#!/bin/bash
container_name=$2
paths=$3 # takes the second argument to be the bindings for the container

##todo: resolve paths
set -o pipefail # controls script behaviour

## Define variables
thisdir=$PWD
containerdir="${thisdir}/containers"
container="${containerdir}/${container_name}"
address=127.0.0.1
port_max=8100
port_min=8000
port="$(comm -23 <(seq "${port_min}" "${port_max}" | sort) <(ss -Htan | awk "{print $4}" | cut -d":" -f2 | sort -u) | shuf | head -n 1)"
### switch for cuda
if [[ -d  "/opt/Bio/cuda-toolkit/11.6/bin" ]]
then	
	cuda_lib="True"
else 
	cuda_lib="False"
fi

### switch for pathset
if [[ -z  "${paths}" ]]
then 
	pathset="False"
else 
	pathset="${paths}"
fi

# Define help
help(){
  cat <<EOF
Usage ./rstudio_me [[task] [container_name|instance_name] [pathset]]

Manage RStudio Server sessions in this folder.

tasks:
start_rstudio		Start a new RStudio server session.
start_jupyter		Start a new Jupyter server session.
list_ins		List all running instances
stop_ins		Stop running instance with a provided name

container_name:		Define name of the container or sandbox folder

instance_name:		Name of the instance you want to stop. 

pathset:		Set all paths you want to have in the container, comma-seperated.
			If you omit a path, only \$HOME and \$PWD (currently $PWD) will be in the container (but only if $PWD is not on a seperate mount point)
                  
			For example, /filer,/hsm will mount /filer and /hsm into the container
			WARNING: avoid using /
EOF
}

# Create instance
start_instance(){
	# put all variables in a json file
	container_inputs=$(singularity exec -H "${thisdir}:/proj" "${container}" python3 /usr/lib/usr_scr/make_dirs.py "${ide_type}" "${thisdir}" "${port}" "${pathset}" "${cuda_lib}")
	
	# define variables
	ins_name=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.ins' ${container_inputs})
	tmp_dir=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.tmp' ${container_inputs})
	bindings=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.bindings' ${container_inputs})
	logs=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.log' ${container_inputs})
	err=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.err' ${container_inputs})

	# start instance
	singularity instance start --nv \
		--contain \
		-W "${tmp_dir}" \
		-H "${thisdir}:/proj" \
		-B "${bindings}" \
		"${container}" \
		"${ins_name}"
}

# Define pid information store
set_pid(){

	if [[ -f  "${pid_info}" ]]
  	then
    		rm -f  "${pid_info}"
    		touch  "${pid_info}"
  	else
		touch  "${pid_info}"
  	fi
  
	cat <<EOF >"${pid_info}"
${pid_ins}
${ins_name}
${address}:${port}
${hostname}
EOF
}

# Start rstudio
start_rstudio(){
	# start instance
	start_instance
	
	# start ide
	(DEBUG_AUTH_FILE=false \
	USER=$(whoami) \
	RSTUDIO_PASSWORD="hello" \
	singularity exec \
		--pwd "/proj" \
		"instance://${ins_name}" \
		rserver \
        --www-address "${address}" \
        --www-port "${port}" \
        --auth-none 0 \
		--server-user "${USER}" \
        --auth-pam-helper "rstudio_auth" \
		--database-config-file "/etc/rstudio/database.conf" \
		> "${logs}" \
		2> "${err}") &
	
	# process pid
	pid_ins=$!
	disown "${pid_ins}"
  	set_pid
  	echo "Acess the rstudio instance - ${ins_name} at ${address}:${port}"
}

# Create Jupyter
start_jupyter(){
	# start instance
	start_instance

	# start ide	
	(singularity exec \
 		--pwd "/proj/" \
 		"instance://${ins_name}" \
 		jupyter lab \
        --ip="${address}" \
        --port="${port}" \
		--ServerApp.root_dir="/proj/" \
		> "${logs}" \
		2> "${err}") &

	# process ide
  	pid_ins=$!
  	disown "${pid_ins}"
  	set_pid
  	echo "Acess the jupyter instance - ${ins_name} at ${address}:${port}"
}

# list running instance
list_ins(){
	instances=$(singularity instance list -j | jq '.instances[]')
	echo "${instances}"
}

# stop running instance
stop_ins(){
  	ins_name=$1
  	singularity instance stop "${ins_name}"
}

if [ "$#" = 0 ]; then
  echo ""
  echo "This script needs some argument to work."
  echo "Plear run ./rstudio_me help to see the usage tips"
  echo ""
  exit 1
else
  cmd="$1"
  shift
fi

case $cmd in
  start_rstudio)
  	ide_type="rst"
	pid_info="${thisdir}/${ide_type}/${ide_type}.pid" # modify this to be universal
  	start_rstudio "$@"
  ;;
  start_jupyter)
  	ide_type="jup"
	pid_info="${thisdir}/${ide_type}/${ide_type}.pid" # modify this to be universal
  	start_jupyter "$@"
  ;;
  list_ins) 
  	list_ins "$@"
  ;;
  stop_ins) 
  	stop_ins "$@"
  ;;
  help) help
esac