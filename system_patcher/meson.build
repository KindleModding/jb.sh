project('system_patcher', 'c', version : '4.1.0', default_options: ['warning_level=everything', 'c_std=gnu23'])
subproject('cjson', default_options: ['default_library=static', 'tests=false']).get_variable('libcjson_dep')
cjson_dep = dependency('libcjson')

sources = files(
    'main.c'
)

executable('kmc_system_patcher', sources, include_directories: [], dependencies: [cjson_dep])