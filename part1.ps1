#[INFO] dynamique object subnet to inject in ARM
$subnets=@()
foreach ( $network in $networks.GetEnumerator() ){
        $subnets+= @{
                        name = $($network.name)
                        properties = @{
                                addressPrefix = "$($prefixip)$($network.value)"
                        }
                }
}
#[INFO] Convert object en Json, ARM will understand json
$subnetJson=$(ConvertTo-Json $subnets -Depth 99 -Compress)

#[INFO] Create INFRA resource group
if (-not (Get-AzureRMResourceGroup -Name $ResourceGroupInfra -ErrorAction SilentlyContinue)) {
    New-AzureRmResourceGroup -Name $ResourceGroupInfra -Location $ResourceGroupLocation -Tags $TagsInfra
} else {
    Set-AzureRmResourceGroup -Name $ResourceGroupInfra -Tags $TagsInfra
}

#[INFO] running ARM INFRA with json
$ArmOutput = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\infra.json" `
-ResourceGroupName $ResourceGroupInfra `
-DeploymentName "DeployInfra" `
-TemplateParameterObject @{ 
                                virtualNetworks_name     = $networkName
                                vnetPrefix               = $prefixip
                                subnets                  = $subnetJson.tostring()
                        }