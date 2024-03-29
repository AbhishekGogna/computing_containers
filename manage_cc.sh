#!/bin/bash
## todo: expand following section to resolve all user commands at the top
set -o pipefail # controls script behaviour
for ARGUMENT in "${@:2}" # fist place is reserved for the script command
do
	KEY="$(echo ${ARGUMENT} | cut -f1 -d=)"
	KEY_LENGTH="${#KEY}"
	VALUE="${ARGUMENT:${KEY_LENGTH}+1}"

	export "${KEY}"="${VALUE}"
done #lets user specify variable names from command line input

# Define variables

## For instance : User custom 
thisdir=$PWD
ext_lib_blas="/qg-10/data/AGR-QG/Gogna/computing_containers/OpenBLAS/inst/qg-10.ipk-gatersleben.de/lib/libopenblas.so"
perm_bindings=""
usr_scr="${thisdir}/usr_scr"
cc_dir="/home/abhi/Desktop/computing_containers/containers"
def_cc="cc_jup_rst.sif"

## For instance: Auto generated
if [[ -v cc ]]; then container="${cc_dir}/${cc}" ; else container="${cc_dir}/${def_cc}" ; fi

## For startup address
address=127.0.0.1
port_max=8100
port_min=8000
port="$(comm -23 <(seq "${port_min}" "${port_max}" | sort) <(ss -Htan | awk "{print $4}" | cut -d":" -f2 | sort -u) | shuf | head -n 1)"

## switch for cuda
if [[ -d  "/opt/Bio/cuda-toolkit/11.6/bin" ]]; then	cuda_lib="True"; else	cuda_lib="False"; fi

## switch for pathset
if [[ -z  "${paths}" ]]; then	pathset="False"; else	pathset="${paths}"; fi

# Define help
help(){
  cat <<EOF
Usage ./manage_cc task cc|ins="cc_*.sif|ins_*_28_03_23_*" paths="/path/outside:/path/inside"

Manage RStudio Server sessions in this folder.

tasks:
start_rst		Start a new RStudio server session
start_jup		Start a new Jupyter server session
start_bash		Start a interactive bash terminal
list_ins		List all running instances
stop_ins		Stop running instance with a provided name

cc:		Define name of the container or sandbox folder. 
		If not given a default container set by variable "def_container" will be used. 
		Currentely it is set to ${def_container}

ins:		Name of the instance you want to stop. 

paths:		Set all paths you want to have in the container, comma-seperated.
			If you omit a path, only \$HOME and \$PWD (currently ${thisdir}) will be in the container (but only if ${thisdir} is not on a seperate mount point)
                  
			For example, /filer,/hsm will mount /filer and /hsm into the container
			WARNING: avoid using /
EOF
}

# Create instance
start_instance(){
	# put all variables in a json file
	container_inputs=$(singularity exec -H "${thisdir}:/proj" -B "${usr_scr}/make_dirs.py:/usr/lib/usr_scr/make_dirs.py" "${container}" python3 /usr/lib/usr_scr/make_dirs.py "${ide_type}" "${thisdir}" "${port}" "${pathset}" "${cuda_lib}")
	
	# define variables
	ins_name=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.ins' ${container_inputs})
	ins_port=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.port' ${container_inputs})
	tmp_dir=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.tmp' ${container_inputs})
	bindings=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.bindings' ${container_inputs})
	logs=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.log' ${container_inputs})
	err=$(singularity exec -H "${thisdir}:/proj" "${container}" jq -r '.err' ${container_inputs})

	### switch for OpenBLAS
	if [[ -f "${ext_lib_blas}" ]]; then	bindings="${bindings},${ext_lib_blas}:/usr/local/lib/R/lib/libRblas.so";	fi

	## Add permanent bindings 
	if [[ ! -z "${perm_bindings}" ]];	then	bindings="${bindings},${perm_bindings}";	fi

	# start instance
	singularity instance start --nv \
		--contain \
		-W "${tmp_dir}" \
		-H "${thisdir}:/proj" \
		-B "${bindings}" \
		-B "${usr_scr}/make_dirs.py:/usr/lib/usr_scr/make_dirs.py" \
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
${address}:${ins_port}
${tmp_dir}
EOF
}

# Start Bash 
start_bash(){
	# start instance
	start_instance
	echo "Close the instance with name - ${ins_name} "

	# start bash
	singularity exec \
		--pwd "/proj" \
		"instance://${ins_name}" \
		bash
	
}

# Start rstudio
start_rstudio(){
	# start instance
	start_instance
	
	# start ide
	(DEBUG_AUTH_FILE=true \
	USER=$(whoami) \
	RSTUDIO_PASSWORD="hello" \
	singularity exec \
		--pwd "/proj" \
		"instance://${ins_name}" \
		rserver \
        --www-address "${address}" \
        --www-port "${ins_port}" \
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
  	echo "Acess the rstudio instance - ${ins_name} at ${address}:${ins_port}"
}

# Create Jupyter
start_jupyter(){
	# start instance
	start_instance

	# start ide	
	(singularity exec \
 		--pwd "/proj" \
 		"instance://${ins_name}" \
 		jupyter lab \
        --ip=${address} \
        --port="${ins_port}" \
		--ServerApp.root_dir="/proj/" \
		> "${logs}" \
		2> "${err}") &

	# process ide
  	pid_ins=$!
  	disown "${pid_ins}"
  	set_pid
  	echo "Acess the jupyter instance - ${ins_name} at ${address}:${ins_port}"
}

# list running instance
list_ins(){
	instances=$(singularity instance list -j | jq -r '["ins", "pid", "image_path"], (.instances[] | [.instance, .pid, .img] )| @tsv')
	echo "${instances}"
}

# stop running instance
stop_ins(){
	if [[ -v ins ]]
	then
  		singularity instance stop "${ins}"
		if [[ "$ins" == *"rst"* ]]		
		then
			rm -rf "${thisdir}/cc_data/rst/${ins}"
		elif [[ "$ins" == *"jup"* ]]
		then
			rm -rf "${thisdir}/cc_data/jup/${ins}"
		elif [[ "$ins" == *"bash"* ]]
		then
			rm -rf "${thisdir}/cc_data/bash_int/${ins}"
		else
			echo "tmp dir was not deleted. please check."
		fi
	else
		echo "Please pass argument for assignment of ins variable. Check help"
		exit 1
	fi
}

if [ "$#" = 0 ]; then
  echo ""
  echo "This script needs some argument to work."
  echo "Plear run ./manage_cc help to see the usage tips"
  echo ""
  exit 1
else
  cmd="$1"
  shift
fi

case $cmd in
  start_rst)
  	ide_type="rst"
	pid_info="${thisdir}/cc_data/${ide_type}/${ide_type}.pid" # modify this to be universal
  	start_rstudio "$@"
  ;;
  start_jup)
  	ide_type="jup"
	pid_info="${thisdir}/cc_data/${ide_type}/${ide_type}.pid" # modify this to be universal
  	start_jupyter "$@"
  ;;
  start_bash)
	ide_type="none"
  	start_bash "$@"
  ;;
  list_ins) 
  	list_ins "$@"
  ;;
  stop_ins) 
  	stop_ins "$@"
  ;;
  help) help
  ;;
  *) help
  ;;
esac
