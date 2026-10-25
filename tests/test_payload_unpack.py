"""Run with Python 3, xz, GNU base64, and BusyBox on PATH.

JB_TEST_RUNNER overrides 'busybox sh', for example with a Docker command
mounting the temporary directory at the same path. Only the generated unpack
prelude runs; its staging path is redirected and no installation jobs run.
"""
import base64
import io
import lzma
import os
from pathlib import Path
import re
import shlex
import subprocess
import tarfile
import tempfile
import unittest

PACKER = Path(__file__).resolve().parents[1] / 'build_jobs/08_pack_tar_files.sh'
REQUIRED = ('kindlepw2/bin/fbink', 'kindlehf/bin/fbink',
            'system_patches/patch_system.sh')


class PayloadUnpackTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'build').mkdir()
        self.stage = self.root / 'stage'
        self.marker = self.root / 'installation-reached'
        self.runner = shlex.split(os.environ.get('JB_TEST_RUNNER', 'busybox sh'))

    def build(self, names=REQUIRED):
        with tarfile.open(self.root / 'build/kmc.tar', 'w') as archive:
            for name in names:
                data = ('fixture:' + name).encode()
                member = tarfile.TarInfo(name)
                member.size = len(data)
                archive.addfile(member, io.BytesIO(data))
        subprocess.run(['sh', str(PACKER)], cwd=self.root, check=True)
        return (self.root / 'build/jb.sh').read_text()

    def run_script(self, script):
        script = script.replace('/tmp/kmc', str(self.stage))
        script += '\nprintf "reached" > ' + shlex.quote(str(self.marker)) + '\n'
        return subprocess.run(self.runner, input=script, text=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def change_payload(self, script, transform):
        match = re.search(r'echo "([A-Za-z0-9+/=]+)" \| base64 -d', script)
        data = transform(base64.b64decode(match.group(1)))
        return (script[:match.start(1)] + base64.b64encode(data).decode()
                + script[match.end(1):])

    def assert_stopped(self, script):
        result = self.run_script(script)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse(self.marker.exists())
        self.assertFalse(self.stage.exists())

    def test_valid_payload_and_shell_options(self):
        script = self.build() + '\nfalse | true\n[ "$?" -eq 0 ] || exit 99\n'
        result = self.run_script(script)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.marker.exists())
        for name in REQUIRED:
            self.assertEqual((self.stage / name).read_text(), 'fixture:' + name)
        compressed = (self.root / 'build/kmc.tar.xz').read_bytes()
        self.assertEqual(lzma.decompress(compressed, memlimit=13 * 1024**2),
                         (self.root / 'build/kmc.tar').read_bytes())

    def test_truncated_payload(self):
        self.assert_stopped(self.change_payload(self.build(), lambda b: b[:len(b)//2]))

    def test_bad_footer_after_files(self):
        self.assert_stopped(self.change_payload(
            self.build(), lambda b: b[:-12] + bytes([b[-12] ^ 1]) + b[-11:]))

    def test_empty_tar(self):
        self.assert_stopped(self.build(()))

    def test_missing_pw2_file(self):
        self.assert_stopped(self.build(REQUIRED[1:]))

    def test_missing_hf_file(self):
        self.assert_stopped(self.build((REQUIRED[0], REQUIRED[2])))

    def test_missing_system_patch(self):
        self.assert_stopped(self.build(REQUIRED[:2]))

    def test_build_stops_without_input(self):
        result = subprocess.run(['sh', str(PACKER)], cwd=self.root,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'build/jb.sh').exists())


if __name__ == '__main__':
    unittest.main()
