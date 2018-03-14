#[INFO] Create Misc resource group
if (-not (Get-AzureRMResourceGroup -Name $ResourceGroupMisc -ErrorAction SilentlyContinue)) {
     New-AzureRmResourceGroup -Name $ResourceGroupMisc -Location $ResourceGroupLocation -Tags $TagsMisc
 } else {
     Set-AzureRmResourceGroup -Name $ResourceGroupMisc -Tags $TagsMisc
 }

#[INFO] create automation 
$outARMAutomation = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\automation.json" `
-ResourceGroupName $ResourceGroupMisc `
-DeploymentName "DeployMiscAutomation" `
-TemplateParameterObject @{ 
                                automationAccName     = $AutomationName
                        }
    
#[INFO] create storage using like repository of azure automation
$outARMStockage = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\storageacc.json" `
-ResourceGroupName $ResourceGroupMisc `
-DeploymentName "DeployMiscStockage" `
-TemplateParameterObject @{ 
                                storageAccName     = $StockageName
                                storageAccountType = "Standard_LRS"
                        }
