######################################################################
# Created By @RicardoConzatti | November 2016
# www.Solutions4Crowds.com.br
######################################################################
# Access the "Initial-configuration-for-vSphere-with-iSCSI.xlsx"
# to configure your variables or edit the variables below according
# to your needs. Recommended for Nested Lab
######################################################################
$S4Ctitle = "Initial configuration for vSphere with iSCSI v2.0"
### BEGIN CONFIGURATION ###
# vCenter Server
$vCenter = 'lab-n-vc1c.s4c.local'
$vCadmin = 'administrator@vsphere.local'
$vCpass = 'VMware1!'

# Data Center & Cluster
$MyDC = 'S4C NESTED'
$MyCluster = 'S4C-SRV'

# Network
$MyVDS = 'S4C-VDS'
$NumUplink = '2'
$NumPortPG = '8'
$MyFirstNic = 'vmnic1'
$MySecondNic = 'vmnic0'
$MyDefaultVSS = 'vSwitch0'
$NumPG = 3
$MyPG = "LAN","DMZ","LAB"
$MyVLANPG = "11","12","13"
$MyPGMGMT = 'PG-MANAGEMENT'
$MyVLANMGMT = '0'
$MyPGvMotion = 'PG-VMOTION'
$MyVLANvMotion = '15'

# Network iSCSI
$MyVDSiSCSI = 'S4C-VDS-ISCSI'
$MyFirstNiciSCSI = 'vmnic2'
$MySecondNiciSCSI = 'vmnic3'
$MyiSCSItarget = '10.0.2.103'
$MyPGiSCSI1 = 'iSCSI-1'
$MyVLANiSCSI1 = '0'
$MyPGiSCSI2 = 'iSCSI-2'
$MyVLANiSCSI2 = '0'
$MyMTUiSCSI = '9000'

# Hosts ESXi
$MyESXiPass = 'VMware1!'
$MyNTP = '10.10.101.1'
$NumHost = 3
$MyHosts = "lab-n-esxi1c.s4c.local","lab-n-esxi2c.s4c.local","lab-n-esxi3c.s4c.local"
$MyIPvMotionHosts = "10.10.10.1","10.10.10.2","10.10.10.3"
$MyMaskvMotion = '255.255.255.0'
$MyIPiSCSI1Hosts = "10.0.2.67","10.0.2.68","10.0.2.69"
$MyIPiSCSI2Hosts = "10.0.3.67","10.0.3.68","10.0.3.69"
$MyMaskiSCSI = '255.255.255.0'
### END CONFIGURATION ###
######################################################################
############################# TEST SERVERS ###########################
######################################################################
cls
write-host "Initial configuration for vSphere with iSCSI v2.0" 
write-host "www.Solutions4Crowds.com.br" 
write-host
write-host "============================" 
write-host
write-host "Test Connection with the ESXi hosts and vCenter Server" 
write-host
# Flush and Register - Disabled by default
#write-host "Running FlushDNS..."
#ipconfig /flushdns | Out-Null
#write-host "FlushDNS OK!" -foregroundcolor "green" 
#write-host
#write-host "Running RegisterDNS..." 
#ipconfig /registerdns | Out-Null
#write-host "RegisterDNS OK!" -foregroundcolor "green"
write-host
# Test vCenter
write-host "Testing Servers..." 
If (Test-Connection $vCenter -count 4 -quiet) {write-host "$vCenter OK!" -foregroundcolor "green"} 
else {write-host "$vCenter FAIL | Check network / DNS entry" -foregroundcolor "red"; $ConnectionError = 1;}
# Test Hosts
$NumHostTotal = 0
while($NumHost -ne $NumHostTotal) {
	If (Test-Connection $MyHosts[$NumHostTotal] -count 4 -quiet) {write-host $MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"} 
	else {write-host $MyHosts[$NumHostTotal]"FAIL | Check network / DNS entry" -foregroundcolor "red"; $ConnectionError = 1;}
	$NumHostTotal++;
}
If ($ConnectionError -gt 0) {
	write-host
	write-host "### FAIL ###`nCheck the erros and verify your network / DNS" -foregroundcolor "red"; exit}
else {
	write-host
	write-host "### SUCCESS ###" -foregroundcolor "green"
	write-host
	write-host "============================" 
	write-host
	write-host "Connecting to vCenter Server $vCenter..." 
	Start-Sleep -Seconds 8	
}
######################################################################
####################### CONNECT VCENTER SERVER #######################
######################################################################
Connect-VIServer $vCenter -u $vCadmin -password $vCpass | Out-Null
write-host "Connected to $vCenter" -foregroundcolor "green"
write-host
write-host "Starting script..." 
Start-Sleep -Seconds 4
cls
write-host $S4Ctitle 
write-host "www.Solutions4Crowds.com.br" 
write-host
write-host "============================" 
write-host
######################################################################
############################# DATA CENTER ############################
######################################################################
write-host "Creating Data Center..." 
# Create Data Center
New-Datacenter -Location (Get-Folder -NoRecursion) -Name $MyDC | Out-Null
write-host "Data Center $MyDC OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
######################################################################
############################## CLUSTER ###############################
######################################################################
write-host "Creating Cluster..." 
# Create Cluster
New-Cluster -Location $MyDC -Name $MyCluster | Out-Null
write-host "Cluster $MyCluster OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "Adding Hosts to Cluster..." 
$NumHostTotal = 0
while($NumHost -ne $NumHostTotal) {
	# Add to Cluster
	Add-VMHost -Name $MyHosts[$NumHostTotal] -Location $MyCluster -User root -Password $MyESXiPass -Force -RunAsync | Out-Null
	Start-Sleep -Seconds 10
	# Enter Maintenance Mode
	Set-VMHost -VMHost $MyHosts[$NumHostTotal] -State "Maintenance" -RunAsync | Out-Null
	write-host "Host"$MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"
	$NumHostTotal++;
}
write-host
write-host "Hosts OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
######################################################################
################################# VDS ################################
######################################################################
write-host "Creating VDS..." 
# Create VDS
New-VDSwitch -Name $MyVDS -Location $MyDC -NumUplinkPorts $NumUplink -RunAsync | Out-Null
write-host "VDS $MyVDS OK!" -foregroundcolor "green"
# Create VDS iSCSI
New-VDSwitch -Name $MyVDSiSCSI -Location $MyDC -NumUplinkPorts $NumUplink -MTU $MyMTUiSCSI -RunAsync | Out-Null
write-host "VDS $MyVDSiSCSI OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "Creating PortGroups..." 
# Create PortGroup for vMotion
Get-VDSwitch -Name $MyVDS | New-VDPortgroup -Name $MyPGvMotion -VlanId $MyVLANvMotion -NumPorts $NumPortPG -RunAsync | Out-Null
write-host "PortGroup $MyPGvMotion with VLAN $MyVLANvMotion ($MyVDS) OK!" -foregroundcolor "green"
# Create PortGroup for Management
Get-VDSwitch -Name $MyVDS | New-VDPortgroup -Name $MyPGMGMT -VlanId $MyVLANMGMT -NumPorts $NumPortPG -RunAsync | Out-Null
write-host "PortGroup $MyPGMGMT with VLAN $MyVLANMGMT ($MyVDS) OK!" -foregroundcolor "green"
# Create PortGroup for iSCSI-1
Get-VDSwitch -Name $MyVDSiSCSI | New-VDPortgroup -Name $MyPGiSCSI1 -VlanId $MyVLANiSCSI1 -NumPorts $NumPortPG -RunAsync | Out-Null
write-host "PortGroup $MyPGiSCSI1 with VLAN $MyVLANiSCSI1 ($MyVDSiSCSI) OK!" -foregroundcolor "green"
# Create PortGroup for iSCSI-2
Get-VDSwitch -Name $MyVDSiSCSI | New-VDPortgroup -Name $MyPGiSCSI2 -VlanId $MyVLANiSCSI2 -NumPorts $NumPortPG -RunAsync | Out-Null
write-host "PortGroup $MyPGiSCSI2 with VLAN $MyVLANiSCSI2 ($MyVDSiSCSI) OK!" -foregroundcolor "green"
Start-Sleep -Seconds 5
# Modify PortGroup iSCSI-1 - dvUplink1 ACTIVE | dvUplink2 UNUSED
Get-VDPortgroup -Name $MyPGiSCSI1 | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink1" -UnusedUplinkPort "dvUplink2" | Out-Null
write-host "PortGroup $MyPGiSCSI1 teaming and failover OK!" -foregroundcolor "green"
# Modify PortGroup iSCSI-2 - dvUplink2 ACTIVE | dvUplink1 UNUSED
Get-VDPortgroup -Name $MyPGiSCSI2 | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink2" -UnusedUplinkPort "dvUplink1" | Out-Null
write-host "PortGroup $MyPGiSCSI2 teaming and failover OK!" -foregroundcolor "green"
$NumPGTotal = 0
while($NumPG -ne $NumPGTotal) {
	# Create PortGroup for Virtual Machines
	Get-VDSwitch -Name $MyVDS | New-VDPortgroup -Name $MyPG[$NumPGTotal] -VlanId $MyVLANPG[$NumPGTotal] -NumPorts $NumPortPG -RunAsync | Out-Null
	write-host "PortGroup"$MyPG[$NumPGTotal]"with VLAN"$MyVLANPG[$NumPGTotal]"OK!" -foregroundcolor "green"
	$NumPGTotal++;
}
write-host "Port Groups OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
######################################################################
############################ ESXI HOSTS ##############################
######################################################################
$MyFirstVMKiSCSI = "vmk2" # VMkernel iSCSI-1 - vmk2
$MySecondVMKiSCSI = "vmk3" # VMkernel iSCSI-2 - vmk3
# vmk0 Management | vmk1 vMotion
$NumHostTotal = 0
while($NumHost -ne $NumHostTotal) {
	write-host "Configuring"$MyHosts[$NumHostTotal]"..." 
	# Add to VDS
	Get-VDSwitch -Name $MyVDS | Add-VDSwitchVMHost -VMHost $MyHosts[$NumHostTotal] | Out-Null
	write-host "Add to VDS $MyVDS OK!" -foregroundcolor "green"
	Get-VDSwitch -Name $MyVDSiSCSI | Add-VDSwitchVMHost -VMHost $MyHosts[$NumHostTotal] | Out-Null
	write-host "Add to VDS $MyVDSiSCSI OK!" -foregroundcolor "green"
	# Add First NIC - Uplink
	$MyFirstNicHost = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -Physical -Name $MyFirstNic
	Get-VDSwitch $MyVDS | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $MyFirstNicHost -Confirm:$false | Out-Null
	write-host "Configure NIC OK!" -foregroundcolor "green"
	# Add First NIC iSCSI - Uplink
	$MyFirstNicHostiSCSI = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -Physical -Name $MyFirstNiciSCSI
	Get-VDSwitch $MyVDSiSCSI | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $MyFirstNicHostiSCSI -Confirm:$false | Out-Null
	# Add Second NIC iSCSI - Uplink
	$MySecondNicHostiSCSI = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -Physical -Name $MySecondNiciSCSI
	Get-VDSwitch $MyVDSiSCSI | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $MySecondNicHostiSCSI -Confirm:$false | Out-Null
	write-host "Configure NIC iSCSI OK!" -foregroundcolor "green"
	# Create VMkernel vMotion
	New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDS -PortGroup $MyPGvMotion -IP $MyIPvMotionHosts[$NumHostTotal] -SubnetMask $MyMaskvMotion -VMotionEnabled $true | Out-Null
	write-host "VMkernel for vMotion OK!" -foregroundcolor "green"
	# Create VMkenel iSCSI 1
	New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDSiSCSI -PortGroup $MyPGiSCSI1 -IP $MyIPiSCSI1Hosts[$NumHostTotal] -SubnetMask $MyMaskiSCSI -MTU $MyMTUiSCSI | Out-Null
	write-host "VMkernel for iSCSI-1 OK!" -foregroundcolor "green"
	# Create VMkernel iSCSI 2
	New-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -VirtualSwitch $MyVDSiSCSI -PortGroup $MyPGiSCSI2 -IP $MyIPiSCSI2Hosts[$NumHostTotal] -SubnetMask $MyMaskiSCSI -MTU $MyMTUiSCSI | Out-Null
	write-host "VMkernel for ISCSI-2 OK!" -foregroundcolor "green"
	# Add iSCSI Software Adapter
	Get-VMHoststorage $MyHosts[$NumHostTotal] | set-vmhoststorage -softwareiscsienabled $True | Out-Null
	write-host "iSCSI Software Adapter OK!" -foregroundcolor "green"
	# Add VMkernel port binding iSCSI
	$esxcli = Get-EsxCli -VMhost $MyHosts[$NumHostTotal]
	$HBAiSCSI = Get-VMHostHba -VMHost $MyHosts[$NumHostTotal] -Type iSCSI | %{$_.Device}
	$esxcli.iscsi.networkportal.add($HBAiSCSI, $Null, $MyFirstVMKiSCSI)
	$esxcli.iscsi.networkportal.add($HBAiSCSI, $Null, $MySecondVMKiSCSI)
	write-host "VMkernel Port Binding ($MyFirstVMKiSCSI and $MySecondVMKiSCSI) OK!" -foregroundcolor "green"
	# Add Send Target Portal
	Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostHba -Type iScsi | New-IScsiHbaTarget -Address $MyiSCSItarget | Out-Null
	write-host "Send Target Portal ($MyiSCSItarget) OK!" -foregroundcolor "green"
	# Rescan all hba and vmfs
	Get-VMHoststorage $MyHosts[$NumHostTotal] -rescanallhba -rescanvmfs | Out-Null
	write-host "Rescan all HBA and VMFS OK!" -foregroundcolor "green"
	# Migrate Management (vSS to vDS)
	$vNicManagement = Get-VMHostNetworkAdapter -VMHost $MyHosts[$NumHostTotal] -Name vmk0
	Add-VDSwitchPhysicalNetworkAdapter -DistributedSwitch $MyVDS -VMHostPhysicalNic $MyFirstNicHost -VMHostVirtualNic $vNicManagement -VirtualNicPortGroup $MyPGMGMT -Confirm:$false | Out-Null
	write-host "Migrate Management Network (VSS to VDS) OK!" -foregroundcolor "green"
	# Add Second NIC - Uplink
	$MySecondNicHost = Get-VMHost $MyHosts[$NumHostTotal] | Get-VMHostNetworkAdapter -Physical -Name $MySecondNic
	Get-VDSwitch $MyVDS | Add-VDSwitchPhysicalNetworkAdapter -VMHostNetworkAdapter $MySecondNicHost -Confirm:$false | Out-Null
	write-host "Configure NIC OK!" -foregroundcolor "green"
	# Configure and Start NTP Service
	Get-VMHost $MyHosts[$NumHostTotal] | Add-VMHostNtpServer -NtpServer $MyNTP | Out-Null
	Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "ntpd"} | Start-VMHostService | Out-Null
	Get-VmHostService -VMHost $MyHosts[$NumHostTotal] | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -policy "on" | Out-Null
	write-host "Configure and Start NTP Server OK!" -foregroundcolor "green"
	write-host
	write-host "vMotion:"$MyIPvMotionHosts[$NumHostTotal]"`niSCSI-1:"$MyIPiSCSI1Hosts[$NumHostTotal]"`niSCSI-2:"$MyIPiSCSI2Hosts[$NumHostTotal] 
	write-host
	write-host $MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"
	write-host
	write-host "============================" 
	write-host
	$NumHostTotal++;
}
######################################################################
############################### OTHER ################################
######################################################################
write-host "Removing VSS ($MyDefaultVSS)..." 
# Remove VSS
Remove-VirtualSwitch -VirtualSwitch $MyDefaultVSS -Confirm:$false
write-host "VSS $MyDefaultVSS OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "Enable HA & DRS / Disable Admission Control / cluster $MyCluster..." 
# Configure Cluster
Get-Cluster $MyCluster | Set-Cluster -HAEnabled:$true -DrsEnabled:$true -Confirm:$false | Out-Null
write-host "Cluster $MyCluster OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "Exiting Maintenance Mode..." 
$NumHostTotal = 0
while($NumHost -ne $NumHostTotal) {
	# Exit Maintenance Mode
	Set-VMHost -VMHost $MyHosts[$NumHostTotal] -State "Connected" -RunAsync | Out-Null
	write-host "Host"$MyHosts[$NumHostTotal]"OK!" -foregroundcolor "green"
	$NumHostTotal++;
}
write-host
write-host "Hosts OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "Disconnecting $vCenter..." 
# Disconnect vCenter Server
Disconnect-VIServer -Server $vCenter -Confirm:$false
write-host "Disconnect OK!" -foregroundcolor "green"
write-host
write-host "============================" 
write-host
write-host "### Finish ###" 
write-host