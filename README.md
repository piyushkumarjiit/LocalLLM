# LocalLLM <br/>
This script can be used to set up a local instance of LLMs. It currently supports Ollama, OpenWebUI and Llama 3.
I tested this on my homelab (Dell R720 with Nvidia 1080TI in passthrough mode) and it works fine.
<br/>
The script would check and install (if missing) below componenets:
<li>curl</li>
<li>Docker</li>
<li>nvidia drivers</li>
<li>nvidia container toolkit</li>
<li>ollama</li>
<li>OpenwebUI</li>
<li>llama3 model</li>
<br/>
There might be need to disconnect and reconnect the session if installing Docker.
Also if we install the Nvidia container toolkit, the script would force a system restart and needs to be reexecuted.
<br/>

## Installation <br/>

In order to execute the script, follow the steps below:
<li> 1. Download the script: <br/>
   <code> wget https://raw.githubusercontent.com/piyushkumarjiit/DctmLifeScienceViaDocker/master/LS_on_Docker.sh </code> </li>
<li> 2. Grant necessary permission <br/>
   <code> chmod 755 setupOllamaOpenUI.sh </code> </li>
<li> 3. execute the script: <br/>
   <code> ./setupOllamaOpenUI.sh |& tee -a  setupOllamaOpenUI.log </code> </li>
