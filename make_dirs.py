#!/bin/python3
import os, sys, re, json
from datetime import date

dir_type = sys.argv[1]
this_dir = sys.argv[2]
date_str = date.today().strftime("%d_%m_%y")
idx = f'{date_str}_{sys.argv[3]}'
paths = sys.argv[4]
if paths:
    pathset=paths.split(',')
else:
    pathset=None
add_cuda=sys.argv[5]

#log
#pid_file

# Define paths
dirs_out = [f'/proj/{dir_type}/ins_{idx}/{x}' for x in ['data', 'config', 'tmp']]

# Make paths absolute
dirs_out_abs = [f'{this_dir}{re.sub("/proj", "", x)}' for x in dirs_out]

# Produce directories
for directory in dirs_out:
    if not os.path.exists(directory):
        os.makedirs(directory)

# Add bindings
## default
default_rst = ['/var/run', '/proj/config']
default_jup = ['/usr/share/jupyter', '/tmp/jupyter']
if dir_type == "rst":
    bindings = [f'{dirs_out_abs[x]}:{default_rst[x]}' for x in range(len(default_rst))]
elif dir_type == "jup":
    bindings = [f'{dirs_out_abs[x]}:{default_jup[x]}' for x in range(len(default_jup))]
    if add_cuda:
        bindings = bindings + ['/opt/Bio/cuda-toolkit/11.6/bin:/usr/local/cuda-11.6/bin']
## user defined
if pathset is not None:
    bindings_all = bindings + pathset
else:
    bindings_all = bindings
bindings_list = ','.join(bindings_all)

# put database config for rst
if dir_type == "rst":
    config_dir = [x for x in dirs_out if "config" in x][0]
    config_info = '''provider=sqlite
directory=/proj/config
'''
    with open(f'{config_dir}/database.conf', 'w') as f:
        f.write(config_info)
    os.system(f'chmod +x {config_dir}/database.conf')

# generate output
output_list = {
    "ins" : f'ins_{dir_type}_{idx}',
    "tmp" : dirs_out_abs[2],
    "bindings" : bindings_list,
    "log" : f'{this_dir}/{dir_type}/ins_{idx}/run.log',
    "err": f'{this_dir}/{dir_type}/ins_{idx}/run.err'}

container_input_path = f'/proj/{dir_type}/ins_{idx}/container_inputs.json'
container_input_path_abs = re.sub("/proj", "", container_input_path)

with open(container_input_path, 'w') as json_file:
    json.dump(output_list, json_file)

print(container_input_path)
