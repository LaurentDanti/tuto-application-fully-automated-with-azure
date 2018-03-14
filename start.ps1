
#select subscription and login

$subscriptionID = "*******"
Try { 
    Select-AzureRmSubscription -SubscriptionId $subscriptionId -ErrorAction Stop
} Catch {
    Add-AzureRmAccount
    Select-AzureRmSubscription -SubscriptionId $subscriptionId -ErrorAction Stop
}


#PART 1 : Start ARM INFRA
$ResourceGroupInfra = "INFRA-RG"
$prefixip = "10.01"
$networkName = "network-NW"
$ResourceGroupLocation = "West Europe"
$networks =  @{
        "TEST-SUBNET"     = ".11.0/24"
        "PROD-SUBNET"     = ".12.0/24"
    }
$TagsInfra = @{
    Env     = "PROD"
    APPS    = "INFRA"
}

. .\part1.ps1
write-output "[Tuto] Look into $ResourceGroupInfra for vnet and subnet"
read-host "Press Enter to continue"


#PART 2 : installation automation, stockage, uploadbinary
$ResourceGroupMisc = "MISC-RG"
$AutomationName = "automation-AU"
$StockageName = "repositoryST"
$TagsMisc = @{
    Env     = "PROD"
    APPS    = "MISC"
}

. .\part2.ps1

write-output "[Tuto] Look into $ResourceGroupMisc \ $AutomationName "
read-host "Press Enter to continue"

. .\common.ps1
#Function UploadBinaryFromLocal in common.ps1
UploadBinaryFromLocal -ResourceGroupName $ResourceGroupMisc -StorageAccount $StockageName `
 -Source @('C:\temp\neo4j-community-3.3.1-windows.zip','C:\temp\jdk-8u112-windows-x64.exe') `
 -ContainerName "neo4j"
 
write-output "[Tuto] Look into storage $ResourceGroupMisc \ $StockageName \ blob"
read-host "Press Enter to continue"


#PART 3 : Configuration DSC
# see DSC\Config.ps1
write-output "[Tuto] Look into file DSC\Config.ps1 "
write-output "[Tuto] differente resource use to install on mutli node, download, decompress"
read-host "Press Enter to continue"


#PART 4 :  create key vault + installation n VM en PROD
$environnement = "PROD"
$Application = "GraphDB"
$ResourceGroupApp = "$environnement-$Application-RG"
$KeyVaultName = "$Application$environnement-KV"
$TagsApp = @{
    Env     = $environnement
    APPS    = $Application
}
$AccWin = "rootwin"
#normaly random generation or get from a KeyStore
$secretWin ="M0t2P@ss"
$AccNeo4j = "neo4jadmin"
#normaly random generation or get from a KeyStore
$secretNeo ="P@ssw0rd"

. .\part4.ps1
write-output "[Tuto] Look password on $ResourceGroupApp \ $KeyVaultName "
write-output "[Tuto] Look on $ResourceGroupApp all resource build vm, loadbalancer, ..."
read-host "Press Enter to continue"

write-output "[Tuto] Try to connect with rdp client to $($outARMVM.Outputs.dns.value):50001 and $($outARMVM.Outputs.dns.value):50002 Login $AccWin and pass $secretWin"
read-host "Press Enter to continue"


#PART 5 : register DSC configuration to node + test Pester
$Configname = "Config"
$Params = @{ 
    "URLRepo" = "https://$StockageName.blob.core.windows.net/neo4j"
    "Path" = "C:\neo4j\" 
    "Version" = "3.3.1"
}

#list module to upload
$ModulesToUp        = @("xPSDesiredStateConfiguration/6.0.0.0")

. .\part5.ps1
write-output "[Tuto] Look status of DSC configuration of VM in $ResourceGroupMisc \ $AutomationName"
read-host "Press Enter to continue"

& ".\healthcheck.ps1" -dnsName $outARMVM.Outputs.dns.value
write-output "[Tuto] try Loadbalancer : http://$($outARMVM.Outputs.dns.value).westeurope.cloudapp.azure.com/browser/index.html"
read-host "Press Enter to continue"


#PART 6 : webapp maintenance (other region)
$RGAppPlan = "DMZ-RG"
$PlanName = "WebPlanNE"
$AppMaintenanceName = "WebAppMaintenance"
$TagsDMZ = @{
    Env     = "PROD"
    APPS    = "DMZ"
}

. .\part6.ps1

write-output "-----------------"
write-output "[TODO] Have you push Web-Maintenance-Page to azure?"
read-host "Press Enter to continue"
write-output "-----------------"
write-output "[Tuto] try webapp maintenance : https://$($AppMaintenanceName).azurewebsites.net"
read-host "Press Enter to continue"

#PART 7 : trafficmanager
$TrafficName = "TFNeo4J"
$DNSTrafficName = "neo4jtuto"
$MonitoringTF = "/browser/index.html"
$MonitoringProtocol = "HTTP"
$MonitoringPort = 80

. .\part7.ps1

write-output "[Tuto] Look the status of endpoint in  $RGAppPlan\$TrafficName"
write-output "[Tuto] try traffic manager http://$DNSTrafficName.trafficmanager.net/"
write-output "[Tuto] try to disable the priority 1 endpoint in  $RGAppPlan\$TrafficName"
write-output "[Tuto] try again traffic manager http://$DNSTrafficName.trafficmanager.net/"
write-output "[Tuto] The page will redirect to maintenance page"
read-host "Press Enter to continue"

#PART 8 : OMS status VM, loadbalancer, traffic

#TUTO 2 : webapp avec release pipeline, scale via test de charge