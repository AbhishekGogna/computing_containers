#!/bin/python3
import os, sys, re, json
from datetime import date

dir_type = sys.argv[1]
this_dir = sys.argv[2]
date_str = date.today().strftime("%d_%m_%y")
idx = f'{date_str}_{sys.argv[3]}'
paths = sys.argv[4]
if paths == "False":
    pathset=None
else:
    pathset=paths.split(',')
add_cuda=sys.argv[5]

# Define paths
ins_name = f'ins_{dir_type}_{idx}'
dirs_out = [f'/proj/{dir_type}/{x}' for x in [f'{ins_name}/data', 'config', f'{ins_name}/tmp']]
default_lib_r = f'/proj/rst/R/x86_64-pc-linux-gnu-library/4.0'
container_input_path = f'/proj/{dir_type}/{ins_name}/container_inputs.json'

# Make paths absolute
dirs_out_abs = [f'{this_dir}{re.sub("/proj", "", x)}' for x in dirs_out]

# Produce directories
for directory in dirs_out:
    if not os.path.exists(directory): 
        os.makedirs(directory)

# Add bindings
## default
default_rst = ['/var/run', '/etc/rstudio']
default_jup = ['/usr/share/jupyter', '/tmp/jupyter']
if dir_type == "rst":
    bindings = [f'{dirs_out_abs[x]}:{default_rst[x]}' for x in range(len(default_rst))]
elif dir_type == "jup":
    bindings = [f'{dirs_out_abs[x]}:{default_jup[x]}' for x in range(len(default_jup))]
    if add_cuda == "True":
        bindings = bindings + ['/opt/Bio/cuda-toolkit/11.6/bin:/usr/local/cuda-11.6/bin']
## user defined
if pathset is not None:
    bindings_all = bindings + pathset
else:
    bindings_all = bindings
bindings_list = ','.join(bindings_all)

# put database config for rst
if dir_type == "rst":
    # add databse config
    config_dir = [x for x in dirs_out if "config" in x][0]
    config_info = '''provider=sqlite
directory={dir}
'''.format(dir=config_dir)
    with open(f'{config_dir}/database.conf', 'w') as f:
        f.write(config_info)
    os.system(f'chmod +x {config_dir}/database.conf')
    # add a default lib path
    if not os.path.exists(default_lib_r):
        os.makedirs(default_lib_r)
    # add renviron at /proj 	# set environment variables #https://docs.posit.co/ide/desktop-pro/settings/settings.html and  https://rstats.wtf/r-startup.html
    with open(f'/proj/.Renviron', 'w') as f:
        f.write(f'R_LIBS_USER={default_lib_r}')

# generate output
output_list = {
    "ins" : ins_name,
    "tmp" : dirs_out_abs[2],
    "bindings" : bindings_list,
    "log" : f'{this_dir}/{dir_type}/{ins_name}/run.log',
    "err": f'{this_dir}/{dir_type}/{ins_name}/run.err'}
with open(container_input_path, 'w') as json_file:
    json.dump(output_list, json_file)

print(container_input_path)
