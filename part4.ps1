
#[INFO] Create App resource group
if (-not (Get-AzureRMResourceGroup -Name $ResourceGroupApp -ErrorAction SilentlyContinue)) {
     New-AzureRmResourceGroup -Name $ResourceGroupApp -Location $ResourceGroupLocation -Tags $TagsApp
 } else {
     Set-AzureRmResourceGroup -Name $ResourceGroupApp -Tags $TagsApp
 }

if(! (Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupApp -ErrorAction SilentlyContinue) ) {
    New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupApp -Location $ResourceGroupLocation -Verbose
    <#
    #[INFO] : Use this code to wait the dns form keyvault. 08/01 => no more needed
    Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $DeploymentSpn `
        -PermissionsToSecrets @('all') -PassThru -Verbose
    do{
        $Logger.INFO("Start waiting $KeyVaultName...")
        $OutputVariable = (ipconfig /flushdns) | Out-String
        Start-Sleep 5
        $resultat=$(try {
                    [System.Net.Dns]::GetHostAddresses("$KeyVaultName.vault.azure.net")
                    throw "ERROR"
                    }
                    catch { 
                        $false
                    } )
    }while ($resultat -eq $false)
    #>
}


#[INFO] Function SetKeyVault in common.ps1
#[INFO] Store account and password in Azure KeyVault
SetKeyVault -AccountName $AccWin -Secret $secretWin
SetKeyVault -AccountName $AccNeo4j -Secret $secretNeo


$dataARM = @{
    virtualMachineNamePrefix = "gr$($environnement.ToLower())vm"
    namePrefix = "gr$($environnement.ToLower())"
    instanceCount = 2
    adminUsername = $AccWin
    adminPassword = $secretWin
    subnetName = "$environnement-SUBNET"
    virtualNetworkName = $networkName
    virtualNetworkResourceGroup = $ResourceGroupInfra
}

<#
    Si vous souhaitez vous connecter au serveur vous pouvez utilisé ippublic front avec les port 50001 (vm1) et 50002 (vm2)
    Dans un system sécurisé nous n'exposerons pas en externe cette feature que nous garderons dans le réseau privé
    (enlever "inboundNatRules" dans le loadbalancer fwd de 50001 et 50002 vers 3389 des VM)

    Si vous souhaitez vous connecter proprement au serveur distant en remote il est préférable d utiliser un certificat 
    afin de passer les credentials de connexion via SSL.
    Pour cela un autre post traitera le sujet avec le template azuredeploy_nvm_secure_remote.json, keyvault et les paramètres ARM suivant 
    winrmCertificateResourceGroup =
    winrmCertificateKeyvault =
    winrmCertificateName =
#>


$outARMVM = New-AzureRmResourceGroupDeployment -Verbose -ErrorAction Stop `
-TemplateFile "$PSScriptRoot\ARM\nvm_with_loadBalancer.json" `
-ResourceGroupName $ResourceGroupApp `
-DeploymentName "DeployApp" `
-TemplateParameterObject $dataARM
