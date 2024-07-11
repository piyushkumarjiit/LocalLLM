#!/bin/bash
#Author: Piyush Kumar (piyushkumar.jiit@.com)

# VM with NVIDIA Consumer Graphics card should have below options set
#hypervisor.cpuid.v0	FALSE
#pciPassthru.64bitMMIOSizeGB	64
#pciPassthru.use64bitMMIO	TRUE


#Abort installation if any of the commands fail
set -e

# Define the LLM model to run
MODEL=llama3

#Identify if it is Ubuntu or Centos/RHEL
distro=$(cat /etc/*-release | awk '/ID=/ { print }' | head -n 1 | awk -F "=" '{print $2}' | sed -e 's/^"//' -e 's/"$//')
echo "Distro: "$distro

#Confirm internet connectivity
internet_access=$(ping -q -c 1 -W 1 1.1.1.1 > /dev/null 2>&1; echo $?)

#If Ping is blocked, set manually as a workaround.
#internet_access=0
echo "Internet access: "$internet_access

# Check if curl is installed otherwise install it
curl_installed=$(curl -V > /dev/null 2>&1; echo $?)
if [[ $curl_installed -gt 0 ]]
then
	echo "curl does not seem to be available. Trying to install curl."
	sudo apt install -y curl
	echo "curl is added."
else
	echo "curl is installed."
fi

#Check if Docker needs to be installed
docker_installed=$(docker -v > /dev/null 2>&1; echo $?)
if [[ $docker_installed -gt 0 ]]
then
	#set +e
	#Install Docker on server
	echo "Docker does not seem to be available. Trying to install Docker."
	curl -fsSL https://get.docker.com -o get-docker.sh
	# Remove set -e from script
	#sed -i "s*set -e*#set -e*g" get-docker.sh
	sudo sh get-docker.sh
	#sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
	#sudo dnf -y  install docker-ce --nobest
	sudo usermod -aG docker $USER
	#Enable Docker to start on start up
	sudo systemctl enable docker
	#Start Docker
	sudo systemctl start docker
	#Remove temp file.
	rm get-docker.sh
	#set -e
	#Check again
	docker_installed=$(docker -v > /dev/null 2>&1; echo $?)
	if [[ $docker_installed == 0 ]]
	then
		echo "Docker seems to be working but you need to disconnect and reconnect for usermod changes to reflect."
		echo "Reconnect and rerun the script. Exiting."
		sleep 10
		exit 1
	elif [[ $distro == "centos" ]]
		then
			echo "Unable to install Docker. Trying the nobest option as last resort."
			sleep 2
			sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
			sudo dnf -y  install docker-ce --nobest
			sudo usermod -aG docker $USER
		#Enable Docker to start on start up
		sudo systemctl enable docker
		#Start Docker
		sudo systemctl start docker
		#Check again
		docker_installed=$(docker -v > /dev/null 2>&1; echo $?)
		if [[ $docker_installed != 0 ]]
		then
			echo "Unable to install Docker."
			exit 1
		else
			echo "Docker seems to be working but you need to disconnect and reconnect for usermod changes to reflect."
			sleep 2
			echo "Reconnect and rerun the script. Exiting."
			sleep 5
			exit 1
		fi
	else
		echo "Unable to install Docker."
		sleep 2
		exit 1
	fi
else
	echo "Docker already installed. Proceeding with installation."
fi

# Check if Nvidia drivers are installed otherwise install it. Missing drivers leads to issues wtih ESXI console for the VM.
drivers_installed=$(nvidia-settings -v > /dev/null 2>&1; echo $?)
if [[ $drivers_installed -gt 0 ]]
then
	echo "Nvidia drivers are not installed. Trying to install drivers."
	# Nvidia driver installation
	sudo ubuntu-drivers autoinstall
	# For datacenter/nonvideo graphics cards
	#sudo ubuntu-drivers install --gpgpu
	#sudo reboot
	echo "Nvidia driver installation complete."
else
	driver_version=$(nvidia-settings -v | grep version)
	echo "Nvidia drivers are installed." $driver_version
fi

# Check if NVidia CUDA toolkit is installed otherwise install it
container_toolkit_installed=$(which nvidia-container-toolkit> /dev/null 2>&1; echo $?)
if [[ $container_toolkit_installed -gt 0 ]]
then
	echo "Nvidia Container toolkit does not seem to be available. Trying to install the toolkit."
	## Install Nvidia Container Toolkit
	curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
	&& curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
	sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
	sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
	sudo apt-get update
	sudo apt-get install -y nvidia-container-toolkit
	echo "Toolkit installed."

	echo "CTK runtime configuration"
	# Configure NVIDIA Container Toolkit
	sudo nvidia-ctk runtime configure --runtime=docker
	echo "CTK runtime configured."
	sudo systemctl restart docker
	echo "Need to reboot the system before continuing. Powering off."
	sudo poweroff
else
	echo "Nvidia Container toolkit is installed." 
fi

# Test GPU integration
echo "Testing GPU integration."
toolkit_working=$(sudo docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi > /dev/null 2>&1; echo $?)
if [[ $toolkit_working -gt 0 ]]
then
	echo "Nvidia Container toolkit is not working. Aborting."
	exit 1
else
	echo "Nvidia Container toolkit is working. Proceeding with Ollama and OpenUI." 
	# Download and run Ollama docker image. 
	# TODO: parameterize the storage location so that new learning data can be preserved across restarts
	docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama

	# Dowloand and run the model. Using /bye to download and instantiate the model but then exit to continue with OpenUI
	docker exec -it ollama ollama run $MODEL "/bye"

	# Run OpenUI container
	docker run -d -p 3000:8080 --gpus all --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:cuda

	echo "All done. You can access OpenUI on http://localhost:3000 "
fi

