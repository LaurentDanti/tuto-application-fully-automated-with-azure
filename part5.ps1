
[Object[]]$NodesName = [Object[]]$(Get-AzureRmVM -ResourceGroupName $ResourceGroupApp).name
$ConfigData = @{
    AllNodes = @(
                @{
                    NodeName                    = "*"
                    project                     = $Application  #dont use
                    DeploymentType              = $Application  #dont use
                    ITEnv                       = $environnement   #dont use
                    Neo4jUser                 = "$($ResourceGroupApp)||$AccNeo4j"
                }
                @{
                    NodeName = $NodesName[0]
                    Master = $true
                }
            )
} 

#[INFO] add slave node to configuration data
if($NodesName.Count -gt 1)
{ 
    For ($i=1; $i -lt $NodesName.Count; $i++) {
        $ConfigData.AllNodes+= @{
            NodeName = $NodesName[$i]
            Master = $false
        }
    }
}

foreach ($module in $ModulesToUp){
    $ModuleName=$module.split("/")[0]
    $ModuleVersion=$module.split("/")[1]
    $ModuleLink = "https://www.powershellgallery.com/api/v2/package/$module"
    if( -not ($modazure=Get-AzureRmAutomationModule -Name $ModuleName -ResourceGroupName $ResourceGroupMisc -AutomationAccountName $AutomationName -ErrorAction SilentlyContinue)){
            Write-Output "[INFO] Upload Module $ModuleName "
            New-AzureRmAutomationModule -ResourceGroupName $ResourceGroupMisc -AutomationAccountName $AutomationName -Name $ModuleName -ContentLink $ModuleLink
    }
    else{
        if ($modazure.Version -ne $ModuleVersion ){
            Write-Output "[INFO] Upload Module $ModuleName "
            New-AzureRmAutomationModule -ResourceGroupName $ResourceGroupMisc -AutomationAccountName $AutomationName -Name $ModuleName -ContentLink $ModuleLink
        }
    }
    
}
$AutAcc=Get-AzureRMAutomationAccount -Name $AutomationName -ResourceGroupName $ResourceGroupMisc
$AutAcc | Import-AzureRmAutomationDscConfiguration -SourcePath "$PSScriptRoot\DSC\$Configname.ps1" -Description "Configuration dsc '$Configname'" -Published -force
$Config = $AutAcc | Get-AzureRmAutomationDSCConfiguration -name $Configname
$myCompileJob = $Config |  Start-AzureRmAutomationDscCompilationJob -ConfigurationData $ConfigData -Parameters $Params

Write-Output "[INFO] Compile DSC $($myCompileJob.ConfigurationName)"
while($myCompileJob.EndTime -eq $null -and $myCompileJob.Exception -eq $null) {
    Write-Output "[INFO] Compiling $($myCompileJob.ConfigurationName) $($myCompileJob.Id)"
    $myCompileJob = $myCompileJob | Get-AzureRmAutomationDscCompilationJob
    Start-Sleep -Seconds 3
}
if ($myCompileJob.Exception -ne $null) {
    Write-Output "[ERROR] An error occured while compiling the DSC configuration : $($myCompileJob.Exception)"
    Write-Error $myCompileJob.Exception
    throw "ERROR"
}
Write-Output "[INFO] Finished compiling DSC configuration"

#[INFO] Register nodes to configuration DSC
foreach ( $Nodename in $NodesName ) {
    #use Workflow to parralelle register when you need synchro between conf of nodes
    $Confignamedsc = $Configname + "." + $Nodename 
    Register-AzureRmAutomationDscNode -AzureVMName $Nodename -AzureVMResourceGroup $ResourceGroupApp `
    -ResourceGroupName $ResourceGroupMisc -AutomationAccountName $AutomationName  `
    -NodeConfigurationName $Confignamedsc 
}