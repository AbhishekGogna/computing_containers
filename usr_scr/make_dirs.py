#!/bin/python3
import os, sys, re, json
from datetime import date

# Read arguments
dir_type = sys.argv[1]
if dir_type == "none":
    dir_type = "bash_int"
this_dir = sys.argv[2]
date_str = date.today().strftime("%d_%m_%y")
idx = f'{date_str}_{sys.argv[3]}'
paths = sys.argv[4]
if paths == "False":
    pathset=None
else:
    pathset=paths.split(',')
add_cuda=sys.argv[5]

# Create common variables
ins_name = f'ins_{dir_type}_{idx}'
cc_dest = "/proj"
cc_data = f'{cc_dest}/cc_data' # all data created by this script goes inside here
ide_dir = f'{cc_data}/{dir_type}' # stores persistant data
config_dir = f'{ide_dir}/config'
ins_dir = f'{ide_dir}/{ins_name}' # stores volatile data
ins_dir_abs = f'{this_dir}/{re.sub("/proj/", "", ins_dir)}'
tmp_dir = f'{ins_dir}/tmp'
tmp_dir_abs = f'{this_dir}/{re.sub("/proj/", "", tmp_dir)}'
ins_data_dir = f'{ins_dir}/data'
ins_inputs = f'{ins_dir}/container_inputs.json'
bindings = None # default, if specified it will be updated
#base_dir = "/proj/cc_data"

# Produce common relative and abs paths
dirs_out = [ins_data_dir, config_dir, tmp_dir]
dirs_out_abs = [f'{this_dir}{re.sub("/proj", "", x)}' for x in dirs_out]

if dir_type == "bash_int":
    dirs_out = [tmp_dir]
elif dir_type == "rst":
    dirs_out = [ins_data_dir, config_dir, tmp_dir]
elif dir_type == "jup":
    dirs_out = [ins_data_dir, config_dir, tmp_dir]

# Make dirs
for directory in dirs_out:
    if not os.path.exists(directory): 
        os.makedirs(directory)

# Add stufff for IDE rstudio
if dir_type == "rst":
    default_lib_r = f'{ide_dir}/R/x86_64-pc-linux-gnu-library/4.0'
    default_rst = ['/var/run', '/etc/rstudio']

    # Define bindings
    bindings = [f'{dirs_out_abs[x]}:{default_rst[x]}' for x in range(len(default_rst))]

    # Add databse config
    config_info = '''provider=sqlite
directory={dir}
'''.format(dir=config_dir)
    with open(f'{config_dir}/database.conf', 'w') as f:
        f.write(config_info)
    os.system(f'chmod +x {config_dir}/database.conf')
        
    # Add a default lib path
    if not os.path.exists(default_lib_r):
        os.makedirs(default_lib_r)
        
    # Add renviron at /proj 	# set environment variables #https://docs.posit.co/ide/desktop-pro/settings/settings.html and  https://rstats.wtf/r-startup.html
    with open(f'/proj/.Renviron', 'w') as f:
        f.write(f'R_LIBS_USER={default_lib_r}')

# Add stuff for IDE jupyter
if dir_type == "jup":
    default_jup = ['/usr/share/jupyter', '/tmp/jupyter']
    bindings = [f'{dirs_out_abs[x]}:{default_jup[x]}' for x in range(len(default_jup))]
    if add_cuda == "True":
        bindings = bindings + ['/opt/Bio/cuda-toolkit/11.6/bin:/usr/local/cuda-11.6/bin']

# Add any user defined bindings
if pathset is not None:
    if bindings is not None:
        bindings_all = bindings + pathset
    else:
        bindings_all = pathset
elif pathset is None:
    if bindings is not None:
        bindings_all = bindings
    else:
        bindings_all = ""

# Format bindings for interpretation in bash
if bindings_all != "":
    bindings_list = ','.join(bindings_all)
else:
    bindings_list = bindings_all

# generate output
output_list = {
    "ins" : ins_name,
    "tmp" : tmp_dir_abs,
    "bindings" : bindings_list,
    "log" : f'{ins_dir_abs}/run.log',
    "err": f'{ins_dir_abs}/run.err'}
with open(ins_inputs, 'w') as json_file:
    json.dump(output_list, json_file)

print(ins_inputs)