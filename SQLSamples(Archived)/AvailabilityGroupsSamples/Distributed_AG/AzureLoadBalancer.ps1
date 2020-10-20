$ClusterNetName = "Cluster Network 1"
$ClusterNetName2 = "Cluster Network 2"
$IPResourceName = "IP Address 10.2.0.25" # the IP Address resource name
$IPResourceName2 = "IP Address 10.1.0.25" # the IP Address resource name

$ILBIP = “10.2.0.25” # the IP Address of the Internal Load Balancer (ILB). This is the static IP address for the load balancer you configured in the Azure portal.
$ILBIP2 = “10.1.0.25” # the IP Address of the Internal Load Balancer (ILB). This is the static IP address for the load balancer you configured in the Azure portal.
[int]$ProbePort = 60000

Import-Module FailoverClusters

Get-ClusterResource $IPResourceName | Set-ClusterParameter -Multiple @{"Address"="$ILBIP";"ProbePort"=$ProbePort;"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName";"EnableDhcp"=0}
Get-ClusterResource $IPResourceName2 | Set-ClusterParameter -Multiple @{"Address"="$ILBIP2";"ProbePort"=$ProbePort;"SubnetMask"="255.255.255.255";"Network"="$ClusterNetworkName2";"EnableDhcp"=0}


Get-ClusterResource $IPResourceName | Get-ClusterParameter 

Get-ClusterResource $IPResourceName | Set-ClusterParameter -Name ProbePort 60000
Get-ClusterResource $IPResourceName | Set-ClusterParameter -Name SubnetMask "255.255.255.0"


Get-ClusterResource $IPResourceName2 | Get-ClusterParameter 

Get-ClusterResource $IPResourceName2 | Set-ClusterParameter -Name ProbePort 60000
Get-ClusterResource $IPResourceName2 | Set-ClusterParameter -Name SubnetMask "255.255.255.0"