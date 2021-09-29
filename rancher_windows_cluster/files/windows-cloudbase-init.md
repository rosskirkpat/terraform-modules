curl.exe https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi -o cloudbase.msi
msiexec /i CloudbaseInitSetup.msi /qn /l*v log.txt

C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf 

# config file
@"
[DEFAULT]
# What user to create and in which group(s) to be put.
username=rancher
groups=Administrators
inject_user_password=true  # Use password from the metadata (not random).
first_logon_behaviour=no
# Which devices to inspect for a possible configuration drive (metadata).
# config_drive_raw_hhd=true
# config_drive_cdrom=true
# Path to tar implementation from Ubuntu.
bsdtar_path=C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
# Logging debugging level.
verbose=true
debug=true
# Where to store logs.
logdir=C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init-unattend.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN
use_eventlog=true
logging_serial_port_settings=
# Enable MTU and NTP plugins.
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
# Where are located the user supplied scripts for execution.
local_scripts_path=C:\Program Files (x86)\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
# Services that will be tested for loading until one of them succeeds.
metadata_services=cloudbaseinit.metadata.services.ec2service.EC2Service,
                  cloudbaseinit.metadata.services.httpservice.HttpService
# What plugins to execute.
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin
# Miscellaneous.
allow_reboot=false    # allow the service to reboot the system
stop_service_on_exit=false
"@

# userdata
@"
<powershell>
Start-Transcript -Path "C:\UserData.log" -Append
Stop-Service docker
$env:CATTLE_AGENT_BINARY_URL = "https://raw.githubusercontent.com/rosskirkpat/rke2/feature/windows-install-wait/windows/rke2-install.ps1"
${cluster_registration}
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
</powershell>
"@