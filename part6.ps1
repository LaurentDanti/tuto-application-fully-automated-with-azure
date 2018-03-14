
#[INFO] Create DMZ resource group
if (-not (Get-AzureRMResourceGroup -Name $RGAppPlan -ErrorAction SilentlyContinue)) {
     New-AzureRmResourceGroup -Name $RGAppPlan -Location $ResourceGroupLocation -Tags $TagsDMZ
 } else {
     Set-AzureRmResourceGroup -Name $RGAppPlan -Tags $TagsDMZ
 }

$ParamsAPPplan =  @{
    PlanName           = $PlanName
    Location           = "North Europe"
}
write-output "[INFO] Start deployment $PlanName"
$outARMWebPlan = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\webplan.json" `
-ResourceGroupName $RGAppPlan `
-DeploymentName "DeployWebPlan" `
-TemplateParameterObject $ParamsAPPplan

$ParamsWebAPP = @{
    webAppName         = $AppMaintenanceName
    ResourceGroupPlan  = $RGAppPlan
    PlanName           = $PlanName
    Location           = "North Europe"
}
write-output "[INFO] Start deployment $AppMaintenanceName"
$outARMWebApp = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\webappstatic.json" `
-ResourceGroupName $RGAppPlan `
-DeploymentName "DeployWebAppStatic" `
-TemplateParameterObject $ParamsWebAPP

#[INFO] Get login password to push in azure git repository the maintenance web page
$tmpFile = New-TemporaryFile
$xml = [xml](Get-AzureRmWebAppPublishingProfile -Name $AppMaintenanceName -ResourceGroupName $RGAppPlan -OutputFile $tmpFile)
$username = $xml.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userName").value
$password = $xml.SelectNodes("//publishProfile[@publishMethod=`"MSDeploy`"]/@userPWD").value
remove-item -force $tmpFile

write-output "[TODO] To push data in the WebApp you need to clone a projet and push to azure"
write-output "[TODO] cd C:\sources"
write-output "[TODO] git clone https://github.com/LaurentSwiss/Web-Maintenance-Page Web-Maintenance-Page"
write-output "[TODO] git remote add azure 'https://${username}:$password@$($AppMaintenanceName).scm.azurewebsites.net'"
write-output "[TODO] git push azure master"

#[INFO] This app deploy a local git repositry
#[INFO] You could use the code bellow to run each time the push to azure or you could use a release pipeline using slot testing and push master at this end.
#cd C:\sources
#git clone https://github.com/LaurentSwiss/Web-Maintenance-Page Web-Maintenance-Page
#
#if (! (&git remote | select-string azure -Quiet)) {
#            git remote add azure "https://${username}:$password@$($AppMaintenanceName).scm.azurewebsites.net"
#}
#git push azure master
#git remote -v
#git remote rm azure