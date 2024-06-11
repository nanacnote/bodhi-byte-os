#! /bin/sh

set -e

UBUNTU_CLOUD_DISTRO_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_DISTROS=("ubuntu-cloud")

SCRIPT_NAME=$(basename "$0")
SCRIPT_ROOT=$(dirname "$(realpath "$0")")

VMS_DIR="${SCRIPT_ROOT}/vms"
VOLUME_DIR="${SCRIPT_ROOT}/volume"
RESOURCES_DIR="${SCRIPT_ROOT}/resources"

VM_HOSTNAME="qvm"
VM_USERNAME="maintainer"
VM_PASSWORD="password"

HDA_SIZE=10G
MEM_SIZE=2G

LARGE_INT=999
GUEST_SSH_PORT=9001

BRIDGE_NAME=virbr0


print_help()
{
	cat <<-EOF
Bridge Networking Help:
https://wiki.archlinux.org/title/Network_bridge

Usage:
    $(basename "$0") <command> [options]

Commands:
    install
        Install an OS on an x86 virtual machine

        Options:
            --iso	absolute path to the OS image to use
                    Required:	False

            --pre	use a pre-configured OS image 
                    Required:	False (if --pre flag and --iso flag are both set, --iso flag takes precedence)
                    Options:	$(printf '<%s>\n' "${CLOUD_DISTROS[*]}")

    start
        Start an already installed virtual machine

        Options:
            --img	name of the virtual machines qcow2 hdd image
                    Required:	False

            --vid	number from 1 to 9 used to differential VM mac addr and device ids
                    Required:	False
                    Default:    1

            --port	port(s) for mapping between host and guest (host-port:guest-port)
                    Required:	False
                    Example:	9000:8080,9001:443

            --if	the mode of interfacing with the virtual machine
                    Required:	False
                    Options:	<ssh graphical>
                    Default:	ssh
                    Notes:		A port for SSH can be specified (--if ssh,9000)

    status
        Lookup what virtual machines are up and running

    stop
        Sends a shutdown command to a running virtual machine
    
    create-bridge
        Create a bridge network called ${BRIDGE_NAME}

    remove-bridge
        Remove the ${BRIDGE_NAME} network
EOF
}


agreement_prompt()
{
	read -p "$1 [y/n]: " selection
	if [ "$selection" != "y" ]; then
		exit 0
	fi
}

check_flag()
{
	local flag_name="$1"
	local flag_value="$2"

	if [ -z "$flag_value" ]; then
		printf "Error: The $flag_name flag is required but was not set\n"
		exit 1
	fi
}

generate_cloud_init_data()
{
	BASE_META_DATA=$(cat <<EOF
provider-id: hiramlabs
distro-url: hiramlabs.com
EOF
)

	BASE_USER_DATA=$(cat <<EOF
#cloud-config

hostname: ${VM_HOSTNAME}
fqdn: ${VM_HOSTNAME}.local
manage_etc_hosts: true

ssh_pwauth: true
disable_root: true

groups:
  - ${VM_HOSTNAME}

users:
  - name: ${VM_USERNAME}
    home: /home/${VM_USERNAME}
    shell: /bin/bash
    groups: sudo, ${VM_HOSTNAME}
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false

chpasswd:
  list: |
    root:${VM_PASSWORD}
    ${VM_USERNAME}:${VM_PASSWORD}
  expire: false
  
write_files:
  - content: |-
      [Unit]
      Description=On boot environment prep for ${VM_HOSTNAME}
      [Service]
      Type=oneshot
      ExecStart=/etc/${VM_HOSTNAME}/${VM_HOSTNAME}.sh start
      ExecStop=/etc/${VM_HOSTNAME}/${VM_HOSTNAME}.sh stop
      RemainAfterExit=yes
      [Install]
      WantedBy=multi-user.target
    path: /etc/systemd/system/${VM_HOSTNAME}.service
  - content: |-
      #! /bin/bash
      start()
      {
        mount -v -t 9p -o trans=virtio,version=9p2000.L volume /mnt/volume
        if [ -e "/etc/${VM_HOSTNAME}/ipaddr" ]; then
          local ip=\$(cat "/etc/${VM_HOSTNAME}/ipaddr")
          ip addr add "\${ip}/24" dev ens2
          ip link set ens2 up
        fi
      }
      stop()
      {
        umount /mnt/volume
        if [ -e "/etc/${VM_HOSTNAME}/ipaddr" ]; then
          local ip=\$(cat "/etc/${VM_HOSTNAME}/ipaddr")
          ip addr delete "\${ip}/24" dev ens2
          ip link set ens2 down
        fi
      }
      if [ "\$1" = "start" ]; then
        start
      elif [ "\$1" = "stop" ]; then
        stop
      else
        exit 0
      fi
    path: /etc/${VM_HOSTNAME}/${VM_HOSTNAME}.sh
    permissions: '0755'
  - content: |-
      mkdir -p /mnt/volume;
      systemctl enable ${VM_HOSTNAME}.service;
    path: /tmp/${VM_HOSTNAME}/init.sh
    permissions: '0755'
    
runcmd:
  - /tmp/${VM_HOSTNAME}/init.sh
  - rm /tmp/${VM_HOSTNAME}/init.sh

power_state:
  mode: reboot
EOF
)
}

check_cloud_distro()
{
	local value="$1"
	local ret=0

	for element in "${CLOUD_DISTROS[@]}"; do
	if [ "$element" = "$value" ]; then
		ret=1
		break
	fi
	done
	
	if [ "$ret" -eq 0 ]; then
		printf "Error: $value is not supported for cloud distro install\n"
		printf "\n"
		printf "Below is a list of all the supported cloud distros:\n"
		printf "%s\n" "${CLOUD_DISTROS[@]}"
		exit 1
	fi
}

create_cloud_init_iso()
{
	if [ ! -f "${RESOURCES_DIR}/${CLOUD_INIT_SEED_ISO}" ]; then
		local temp_user_data_file=$(mktemp)
		local temp_meta_data_file=$(mktemp)

		echo "${!1}" > "$temp_user_data_file"
		echo "${!2}" > "$temp_meta_data_file"

		printf "Creating cloud-init ISO\n"
		mkisofs \
			-output "${RESOURCES_DIR}/${CLOUD_INIT_SEED_ISO}" \
			-volid cidata \
			-joliet \
			-rock \
			-iso-level 2 \
			-graft-points \
			"/user-data=${temp_user_data_file}" \
			"/meta-data=${temp_meta_data_file}"
		printf "Deleting temp config files used to create cloud-config\n"
		rm -v $temp_user_data_file
		rm -v $temp_meta_data_file
	fi
}

install_seeded_ubuntu_cloud_img()
{
	CLOUD_INIT_SEED_ISO="${PRE}-cloud-init-seed.iso"

	local distro_image_name=$(basename "$UBUNTU_CLOUD_DISTRO_URL")
	local vm_name="${distro_image_name%.*}-${CLOUD_INIT_SEED_ISO%.*}.qcow2"

	if [ ! -f "${RESOURCES_DIR}/${distro_image_name}" ]; then
		mkdir -p "$RESOURCES_DIR"
		cd "$RESOURCES_DIR"
			printf "Downloading $UBUNTU_CLOUD_DISTRO_URL\n"
			curl -fSL -O "$UBUNTU_CLOUD_DISTRO_URL"
		cd "$OLDPWD"
	fi
	create_cloud_init_iso $@
	cd "$VMS_DIR"
		qemu-img create \
			-f qcow2 \
			-b "${RESOURCES_DIR}/${distro_image_name}" \
			-F qcow2 \
			"$vm_name" \
			"$HDA_SIZE"
		printf "Setting up vm\nThis may take up to 15mins\n"
		trap 'printf "Removing generated cloud init ISO:\n"; \
			rm -v "${RESOURCES_DIR}/${CLOUD_INIT_SEED_ISO}"; \
			[ "$?" -eq 0 ] && \
			printf "Successfully installed vm\nVM can now be started with [start]\n"; \
			printf "\n"; \
			printf "Username:\t${VM_USERNAME}\n"; \
			printf "Password:\t${VM_PASSWORD}\n"; \
			printf "\n";
			' EXIT
		qemu-system-x86_64 \
			-drive "file=${vm_name},format=qcow2,if=virtio" \
			-drive "file=${RESOURCES_DIR}/${CLOUD_INIT_SEED_ISO},format=raw,if=virtio" \
			-m "$MEM_SIZE" \
			-display none \
			-no-reboot
	cd "$OLDPWD"
}

install_vm_from_predefined()
{
	check_flag "--pre" "$PRE"
	check_cloud_distro "$PRE"
	read -p "Install $PRE distro with cloud-init? [y/n]: " selection
	if [ "$selection" = "y" ]; then
		case "$PRE" in
			"${CLOUD_DISTROS[0]}")
				generate_cloud_init_data
				install_seeded_ubuntu_cloud_img BASE_USER_DATA BASE_META_DATA
				;;
			*)
				printf "Internal Error: Switch case missmatch for $PRE\n"
				printf "Internal Error Trace: Line no $LINENO\n"
				;;
		esac

	else
		printf "Installation aborted\n"
		exit 0
	fi

}

install_vm_from_iso()
{
	check_flag "--iso" "$ISO"
	read -p "Install ${ISO}? [y/n]: " selection
	if [ "$selection" = "y" ]; then
        local iso_filename=$(basename "$ISO")
		cd "$VMS_DIR"
            qemu-img create \
                -f qcow2 \
                "${iso_filename%.*}.qcow2" \
                "$HDA_SIZE"
            # TODO: looking into exit code for the trap because with no-reboot exit code is always 1 even after success
            # trap '[ "$?" -eq 1 ] && printf "Deleted ${VMS_DIR}/"; rm -v "${ISO%.*}.qcow2"' EXIT
            qemu-system-x86_64 \
                -drive "file=${iso_filename%.*}.qcow2,format=qcow2,if=virtio" \
                -m "$MEM_SIZE" \
                -cdrom "$ISO" \
                -boot d \
                -no-reboot
        cd "$OLDPWD"
	else
		printf "Installation aborted\n"
		exit 0
	fi
}

install_vm()
{
	mkdir -p "$VMS_DIR"
	if [ -n "$ISO" ]; then
		install_vm_from_iso
	elif [ -n "$PRE" ]; then
		install_vm_from_predefined
	else
		printf "\n"
		printf "Available distros with cloud-init support:\n"
		printf "==========================================\n"

		local counter=1
		for distro in "${CLOUD_DISTROS[@]}"; do
			printf "$counter: $distro\n"
			counter=$((counter + 1))
		done
        
        # TODO:
        # insert another print and list of other none cloud init distros here

		printf "\n"
		read -p "Choose a distro by entering the corresponding number: " selection
		if [ "$selection" -lt 1 ]; then
			selection="$LARGE_INT"
		fi

		local selected_distro="${CLOUD_DISTROS[$selection - 1]}"
		if [ -n "$selected_distro" ]; then
			PRE=$selected_distro
			install_vm_from_predefined
		else
			printf "Error: No matching distro was found for the choice\n"
			exit 1
		fi      
	fi

}

start_vm()
{
	check_flag "--vid" "$VID"
	if [ -n "$IMG" ]; then
		SELECTED_VM="$IMG"
	else
		printf "\n"
		printf "Available virtual machines:\n"
		printf "===========================\n"

		local counter=1
		local vms=()

		for vm in "$VMS_DIR"/*; do
			local vm_name=$(basename "$vm")
			vms["$counter"]="$vm_name"
			printf "$counter: $vm_name\n"
			counter=$((counter + 1))
		done

		printf "\n"
		read -p "Choose a vm by entering the corresponding number: " selection
		if [ "$selection" -lt 1 ]; then
			selection="$LARGE_INT"
		fi
		SELECTED_VM="${vms[$selection]}"
		if [ -z "$SELECTED_VM" ]; then
			printf "Error: No matching vm was found the choice\n"
			exit 1
		fi
	fi

	mkdir -p "$VOLUME_DIR"
	printf "\n"
	printf "Shared volume directory available at:\n"
	printf "\t${VOLUME_DIR}\n"
	printf "\n"
	printf "Shared volume may need mounting from inside the vm:\n"
	printf "\tmount -t 9p -o trans=virtio,version=9p2000.L volume /mnt/volume\n"
	cd "$VMS_DIR"
		case "$IF" in
			"graphical")
				qemu-system-x86_64 \
                    -name "${VM_HOSTNAME}-${SELECTED_VM%.*}" \
                    -drive "file=${SELECTED_VM},format=qcow2,if=virtio" \
                    -m "$MEM_SIZE" \
                    -netdev "type=bridge,id=bnet${VID},br=${BRIDGE_NAME}" \
                    -device "virtio-net-pci,netdev=bnet${VID},mac=${VID}0:11:22:33:44:55" \
                    -netdev "type=user,id=unet${VID},${HOST_FWD}" \
                    -device "virtio-net-pci,netdev=unet${VID}" \
                    -virtfs "local,path=${VOLUME_DIR},mount_tag=volume,security_model=none,id=vol${VID}" \
                    -enable-kvm
				;;
			"ssh")
				qemu-system-x86_64 \
                    -name "${VM_HOSTNAME}-${SELECTED_VM%.*}----${GUEST_SSH_PORT}" \
                    -drive "file=${SELECTED_VM},format=qcow2,if=virtio" \
                    -m "$MEM_SIZE" \
                    -netdev "type=bridge,id=bnet${VID},br=${BRIDGE_NAME}" \
                    -device "virtio-net-pci,netdev=bnet${VID},mac=${VID}0:11:22:33:44:55" \
                    -netdev "type=user,id=unet${VID},hostfwd=tcp::${GUEST_SSH_PORT}-:22${HOST_FWD}" \
                    -device "virtio-net-pci,netdev=unet${VID}" \
                    -virtfs "local,path=${VOLUME_DIR},mount_tag=volume,security_model=none,id=vol${VID}" \
                    -vga none \
                    -monitor none \
                    -display none \
                    -daemonize \
                    -enable-kvm
				printf "\nConnect via SSH:\n\tssh -p $GUEST_SSH_PORT ${VM_USERNAME:-username}@localhost\n"
				;;
            *)
                printf "Error: --if $IF is not one of [ssh, graphical]\n"
                ;;
		esac
	cd "$OLDPWD"
}

status_vm()
{
	if command -v awk > /dev/null 2>&1; then
		ps aux | grep "${VM_HOSTNAME}-.*" | grep -v grep | awk 'BEGIN {printf "%-10s %-10s\n", "PID", "VM NAME"} {printf "%-10s %-10s\n", $2, $13}'
	else
		ps aux | grep "${VM_HOSTNAME}-.*" | grep -v grep
	fi
}

stop_vm()
{
	status_vm

	local pid
	local username

	printf "\nSend a shutdown command to a running vm [may require username and password]\n"
	printf "For vm started with the [--if graphical] flag please use the graphical window to close them\nThe stop command only works for ssh vm running in daemon mode\n"
	printf "\n"

	read -p "PID: " pid
	read -p "USERNAME: " username

	local guest_ssh_port=$(ps aux | grep "$pid" | sed -n 's/.*----\s*\([^ ]*\).*/\1/p')
	ssh -q -t -p "$guest_ssh_port" "${username}@localhost" 'sudo shutdown -h now'
}

create_bridge()
{
    ip link add name ${BRIDGE_NAME} type bridge
    ip link set dev ${BRIDGE_NAME} up
    bridge link
   
    cat <<-EOF
    # --- to add an interface to the bridge ---
    # ip link set eth0 up
    # ip link set eth0 master ${BRIDGE_NAME}
    # --- to remove an interface from the bridge ---
    # ip link set eth0 nomaster
    # ip link set eth0 down
EOF
}

remove_bridge()
{
    ip link delete ${BRIDGE_NAME} type bridge
    bridge link
}

parse_port_flag()
{
	HOST_FWD=""
	array=($(echo "$1" | tr ',' ' '))
	for element in "${array[@]}"; do
		element_split=($(echo "$element" | tr ':' ' '))
		local host="${element_split[0]}"
		local guest="${element_split[1]}"
		if [ -z "$host" ] || [ -z "$guest" ]; then
			printf "Error:\tBoth host and guest ports must be set\n"
			printf "\tUse the format '--port <host:guest>,<host:guest>'\n"
			printf "\tUse a comma delimeter for multiple port forwarding\n" 
			exit 1
		fi
		HOST_FWD="${HOST_FWD},hostfwd=tcp::${host}-:${guest}"
	done
}

parse_if_flag()
{
	array=($(echo "$1" | tr ',' ' '))
	IF="${array[0]}"
	if [ "${array[0]}" = "ssh" ] && [ -n "${array[1]}" ]; then
		GUEST_SSH_PORT="${array[1]}"
	fi
}

parse_vid_flag()
{
	if [ "$1" -ge 1 ] && [ "$1" -le 9 ]; then
		VID="$1"
	else
		printf "Error: The value of --vid can only be a number from 1 to 9 (inclusive)\n"
		exit 1
	fi
}

check_dependencies()
{
    if \
        ! command -v mkisofs > /dev/null 2>&1 ||
        ! command -v qemu-img > /dev/null 2>&1;
    then
        local missing_dependencies=""

        [ ! -x "$(command -v mkisofs)" ] && missing_dependencies="$missing_dependencies mkisofs"
        [ ! -x "$(command -v qemu-img)" ] && missing_dependencies="$missing_dependencies qemu-img"

        printf "The following dependencies are missing: $missing_dependencies.\nPlease install them before proceeding\n"
        exit 1
    fi
}

set_defaul_flags()
{
    # set default flags as stated in print_help here
    VID=1
    IF=ssh
}

parse_options()
{
	if [ "$#" -gt 0 ]; then
		CMD="$1"
		shift
	else
		print_help && exit 1
	fi
	
	while [ "$#" -gt 0 ]; do
		case "$1" in
			"--img")
				shift
				IMG="$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			"--vid")
				shift
				parse_vid_flag "$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			"--if")
				shift
				parse_if_flag "$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			"--iso")
				shift
				ISO="$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			"--port")
				shift
				parse_port_flag "$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			"--pre")
				shift
				PRE="$1"
				if [ -n "$1" ]; then
					shift
				fi
				;;
			*)
				printf "Error: Unknown option $1\n"
				print_help && exit 1
				;;
		esac
	done
}

parse_command()
{
	case "$CMD" in
		"install")
			install_vm
			;;
		"start")
			start_vm
			;;
		"stop")
			stop_vm
			;;
		"status")
			status_vm
			;;
		"create-bridge")
		    create_bridge
			;;
		"remove-bridge")
			remove_bridge
			;;
		*)
			printf "Error: Unknown command $CMD\n"
			print_help && exit 1
			;;
	esac
}

check_dependencies
set_defaul_flags
parse_options "$@"
parse_command

# exit fullscreen -> ctrl + alt + f
# release mouse   -> ctrl + alt + g
