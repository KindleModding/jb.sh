/*
 * xm.c — Scribe 3 / Scribe Colorsoft (paloma/calvados, MT8115, FW 5.20.1)
 * v4 ROOTLESS=0 untethered boot-exec module for the Amazon Kindle.
 *
 * Loaded by the ROOT Xorg 1.20.14 process at every boot via:
 *   /etc/xorg.conf -> /var/local/xorg.conf (symlink, writable partition)
 *   regenerated each boot by /etc/upstart/makexconfig, which splices the
 *   persistent dynconf key `winmgr.colorinverse.pref` (stored in
 *   /var/local/appreg.db) into the "FormatEPDC" option line.
 *
 * v4 Architecture:
 *   1. Synchronous Stage 1 (/var/local/xm/stage1_pivot.sh):
 *      Forks child 1 via sys_clone(SIGCHLD, 0), calls sys_setsid() so it leads
 *      its own process group (PGID == pid1), and execs /bin/sh stage1_pivot.sh.
 *      Parent (Xorg) polls sys_wait4(pid1, &status, WNOHANG, 0) every 10 ms via
 *      sys_nanosleep up to 80 iterations (800 ms hard ceiling). If still running
 *      after 800 ms, sends sys_kill(-pid1, 9) (SIGKILL to the process group) and
 *      reaps with sys_wait4(pid1, &status, WNOHANG, 0).
 *   2. Asynchronous Stage 2 (/var/local/xm/boot.sh):
 *      Double-forks child 2 via sys_clone(SIGCHLD, 0): intermediate child forks
 *      grandchild (which calls sys_setsid() and execs /bin/sh /var/local/xm/boot.sh)
 *      and exits immediately via sys_exit(0); parent reaps intermediate child via
 *      sys_wait4(pid2, &status, 0, 0) so Xorg has zero zombie children.
 *
 * Build (macOS/Linux host, no armhf sysroot required):
 *   zig cc -target arm-linux-musleabihf -Os -fno-unwind-tables \
 *        -fno-asynchronous-unwind-tables -shared -fPIC -nostdlib xm.c -o xm.so
 */

/* 32-bit ARM EABI syscall numbers (verified against Linux 6.6.77-lab126 compat_sys_call_table) */
#define __NR_exit             1
#define __NR_execve          11
#define __NR_kill            37
#define __NR_setsid          66
#define __NR_wait4          114   /* NOTE: __NR_waitpid (7) is unimplemented (-ENOSYS) on ARM EABI */
#define __NR_clone          120
#define __NR_nanosleep      162

#define SIGCHLD              17
#define SIGKILL               9
#define WNOHANG               1

struct timespec32 {
    long tv_sec;
    long tv_nsec;
};

static long __attribute__((noinline))
sys_call4(long n, long a, long b, long c, long d)
{
    register long r7 __asm__("r7") = n;
    register long r0 __asm__("r0") = a;
    register long r1 __asm__("r1") = b;
    register long r2 __asm__("r2") = c;
    register long r3 __asm__("r3") = d;
    __asm__ volatile("svc 0"
                     : "+r"(r0)
                     : "r"(r7), "r"(r1), "r"(r2), "r"(r3)
                     : "memory", "cc");
    return r0;
}

static void __attribute__((noreturn)) sys_exit(int code)
{
    sys_call4(__NR_exit, code, 0, 0, 0);
    __builtin_unreachable();
}

static int sys_clone(unsigned long flags, unsigned long newsp)
{
    return (int)sys_call4(__NR_clone, (long)flags, (long)newsp, 0, 0);
}

static long sys_execve(const char *path, char *const argv[], char *const envp[])
{
    return sys_call4(__NR_execve, (long)path, (long)argv, (long)envp, 0);
}

static void sys_setsid(void)
{
    sys_call4(__NR_setsid, 0, 0, 0, 0);
}

static int sys_wait4(int pid, int *status, int options, void *rusage)
{
    return (int)sys_call4(__NR_wait4, pid, (long)status, options, (long)rusage);
}

static int sys_kill(int pid, int sig)
{
    return (int)sys_call4(__NR_kill, pid, sig, 0, 0);
}

static int sys_nanosleep(const struct timespec32 *req, struct timespec32 *rem)
{
    return (int)sys_call4(__NR_nanosleep, (long)req, (long)rem, 0, 0);
}

static const char kShell[]        = "/bin/sh";
static const char kStage1Script[] = "/var/local/xm/stage1_pivot.sh";
static const char kBootScript1[]  = "/var/local/xm/boot.sh";
static const char kBootScript2[]  = "/var/local/kmc/boot.sh";
static const char kDefaultPath[]  = "PATH=/sbin:/usr/sbin:/bin:/usr/bin";

typedef char *cargv_t;

__attribute__((constructor))
static void xm_init(void)
{
    char *envp[2];
    envp[0] = (char *)kDefaultPath;
    envp[1] = 0;

    /*
     * 1. Fork child 1 (stage1_pivot.sh) and poll wait4(WNOHANG) up to 800 ms.
     */
    int pid1 = sys_clone(SIGCHLD, 0);
    if (pid1 == 0) {
        sys_setsid();
        cargv_t argv1[3];
        argv1[0] = (cargv_t)kShell;
        argv1[1] = (cargv_t)kStage1Script;
        argv1[2] = 0;
        sys_execve(kShell, argv1, envp);
        sys_exit(127);
    } else if (pid1 > 0) {
        int status = 0;
        int reaped = 0;
        struct timespec32 ts10ms;
        ts10ms.tv_sec  = 0;
        ts10ms.tv_nsec = 10000000L; /* 10 ms */

        for (int i = 0; i < 80; i++) {
            int r = sys_wait4(pid1, &status, WNOHANG, 0);
            if (r == pid1 || (r < 0 && r != -4 /* -EINTR */)) {
                reaped = 1;
                break;
            }
            sys_nanosleep(&ts10ms, 0);
        }

        if (!reaped) {
            /* 800 ms hard ceiling reached: kill process group (-pid1) and reap */
            sys_kill(-pid1, SIGKILL);
            sys_kill(pid1, SIGKILL);
            struct timespec32 ts2ms;
            ts2ms.tv_sec  = 0;
            ts2ms.tv_nsec = 2000000L; /* 2 ms */
            for (int j = 0; j < 5; j++) {
                if (sys_wait4(pid1, &status, WNOHANG, 0) != 0)
                    break;
                sys_nanosleep(&ts2ms, 0);
            }
        }
    }

    /*
     * 2. Double-fork child 2 (/var/local/xm/boot.sh) so Xorg has zero zombies.
     */
    int pid2 = sys_clone(SIGCHLD, 0);
    if (pid2 == 0) {
        int pid3 = sys_clone(SIGCHLD, 0);
        if (pid3 == 0) {
            sys_setsid();
            cargv_t argv2[3];
            argv2[0] = (cargv_t)kShell;
            argv2[1] = (cargv_t)kBootScript1;
            argv2[2] = 0;
            sys_execve(kShell, argv2, envp);
            argv2[1] = (cargv_t)kBootScript2;
            sys_execve(kShell, argv2, envp);
            sys_exit(127);
        }
        sys_exit(0);
    } else if (pid2 > 0) {
        int status2 = 0;
        sys_wait4(pid2, &status2, 0, 0);
    }
}
