
$WebAppMaintenance      = Get-AzureRmWebApp -ResourceGroupName $RGAppPlan -Name $AppMaintenanceName
#[INFO] Get public ip of loadbalancing to set traffic manager
$PublicAddress = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupApp -ErrorAction SilentlyContinue
$TargetID = $PublicAddress.Id
$TargeFQDN = $PublicAddress.DnsSettings.Fqdn

$ParamsTraffic = @{
        trafficName                     = $TrafficName 
        trafficdnsName                  = $DNSTrafficName
        targetIpAddressId               = $TargetID
        targetIpAddressFqdn             = $TargeFQDN
        targetIpAddressIdMaintenance    = $WebAppMaintenance.Id
        targetIpAddressFqdnMaintenance  = $WebAppMaintenance.DefaultHostName
        targetLocationMaintenance       = $WebAppMaintenance.Location
        monitoringPath                  = $MonitoringTF
        monitoringProtocol              = $MonitoringProtocol
        monitoringPort                  = $MonitoringPort
    }

$outARMWebApp = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\trafficmanager.json" `
-ResourceGroupName $RGAppPlan `
-DeploymentName "DeployTraffic" `
-TemplateParameterObject $ParamsTraffic