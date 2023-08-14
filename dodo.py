#!/user/bin/python3
import os, time
from datetime import timedelta

#start_time = time.time()

needed_dirs = ['cc_data', 'containers', 'defs', 'run_his', 'usr_scr']
for dir in needed_dirs:
    if not os.path.exists(dir):
        os.makedirs(dir, exist_ok=True)

def task_build_cc_base():
    '''builds the base container with python and R programming languages'''
    task_name = "cc_base"
    log_at = f'run_his/{task_name}.log'
    err_at = f'run_his/{task_name}.err'
    def_file = f'defs/{task_name}.def'
    sif_file = f'containers/{task_name}.sif'

    return {'file_dep': [f'{def_file}'],
            'targets': [f'{sif_file}'],
            'actions': [f'sudo singularity build {sif_file} {def_file} > {err_at} 2> {log_at}']}    
#print(f'task cc_base took {str(timedelta(seconds=(time.time() - start_time)))}')

def task_build_cc_jup():
    '''Add jupyter IDE to base image'''
    task_name = "cc_jup"
    log_at = f'run_his/{task_name}.log'
    err_at = f'run_his/{task_name}.err'
    def_file = f'defs/{task_name}.def'
    sif_file = f'containers/{task_name}.sif'

    return {'file_dep': [f'{def_file}', 'containers/cc_base.sif'],
            'targets': [f'{sif_file}'],
            'actions': [f'sudo singularity build {sif_file} {def_file} > {err_at} 2> {log_at}']}
#print(f'task cc_jup took {str(timedelta(seconds=(time.time() - start_time)))}')

def task_build_cc_jup_rst():
    '''upgrades the base container to add rstudio IDE'''
    task_name = "cc_jup_rst"
    log_at = f'run_his/{task_name}.log'
    err_at = f'run_his/{task_name}.err'
    def_file = f'defs/{task_name}.def'
    sif_file = f'containers/{task_name}.sif'

    return {'file_dep': [f'{def_file}', 'containers/cc_jup.sif'],
            'targets': [f'{sif_file}'],
            'actions': [f'sudo singularity build {sif_file} {def_file} > {err_at} 2> {log_at}']}
#print(f'task cc_jup_rst took {str(timedelta(seconds=(time.time() - start_time)))}')