This script can be used to set up a local instance of LLMs. It currently supports Ollama, OpenWebUI and Llama 3.
I tested this on my homelab (Dell R720 with Nvidia 1080TI in passthrough mode) and it works fine.

The script would check and install (if missing) below componenets:
curl
Docker
nvidia drivers
nvidia container toolkit
ollama
OpenwebUI
llama3 model

There might be need to disconnect and reconnect the session if installing Docker.
Also if we install the Nvidia container toolkit, the script would force a system restart and needs to be reexecuted.

Installation
In order to execute the script, follow the steps below:
1. Download the script:
   wget https://raw.githubusercontent.com/piyushkumarjiit/DctmLifeScienceViaDocker/master/LS_on_Docker.sh
3. Grant necessary permission
   chmod 755 setupOllamaOpenUI.sh
5. execute the script:
   ./setupOllamaOpenUI.sh |& tee -a  setupOllamaOpenUI.log
