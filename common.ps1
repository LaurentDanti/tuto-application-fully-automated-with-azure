
#upload binaire 
Function UploadBinaryFromLocal() {
    param(
        [Parameter(Mandatory=$true)]
        [String] $ResourceGroupName,
    
        [Parameter(Mandatory=$true)]
        [String] $StorageAccount,
    
        [Parameter(Mandatory=$true)]
        [string[]] $Source,
    
        [Parameter(Mandatory=$true)]
        [string] $ContainerName,
    
        [Parameter(Mandatory=$false)]
        [Switch] $Force = $false
    )
    
    $storageAcct = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccount
    $context = $storageAcct.Context

    if((-NOT [string]::IsNullOrWhiteSpace($ContainerName)) -and (-NOT (Get-AzureStorageContainer -Context $context -Name $ContainerName -ErrorAction SilentlyContinue))) {
        New-AzureStorageContainer -Name $ContainerName -Context $context -Permission Container
    }

    foreach($FileUpload in $Source) {   
        if(test-path $FileUpload) {

            $FileName=Split-Path $FileUpload -leaf
            if (-not $Force) {
                if (Get-AzureStorageBlob -Container $ContainerName -Context $Context -Blob $FileName -ErrorAction SilentlyContinue) {
                    Write-Output "Blob $ContainerName/$FileName is already present. Skipping."
                    Continue
                }
            }

            # Upload module to storage
            $blobContent = Set-AzureStorageBlobContent -File "$FileUpload" -Container $ContainerName -Context $context -Force

            $containerUri="$($blobContent.Context.BlobEndPoint)"+$ContainerName
            $contentLink="$containerUri/$FileName"
            Write-Output "[INFO] Link : $contentLink"
        } else {
            Write-Output "[WARN] File $FileUpload does not exist. Not uploading."
        }
    }
}


Function SetKeyVault() {
    param(
        [Parameter(Mandatory=$true)]
        [String] $AccountName,
        [Parameter(Mandatory=$true)]
        [String] $Secret
    )
    if(!( Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $AccountName -ErrorAction SilentlyContinue)){        
        $secretPass = ConvertTo-SecureString $secret -AsPlainText -Force
        $secret=""
        Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $AccountName -SecretValue $secretPass
    }
    <#SET local account for service #>
    $AccountPassword=($(Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $AccountName).SecretValueText)
    $secpasswd = ConvertTo-SecureString $AccountPassword -Force -AsPlainText 
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AccountName, $secpasswd

    if(! (Get-AzureRmAutomationCredential -AutomationAccountName $AutomationName -ResourceGroupName $ResourceGroupMisc -Name "$($ResourceGroupApp)||$AccountName" -ErrorAction SilentlyContinue) ) {
        $Null = New-AzureRmAutomationCredential -AutomationAccountName $AutomationName -ResourceGroupName $ResourceGroupMisc -Name "$($ResourceGroupApp)||$AccountName" -Value $cred
    }
    Set-AzureRmAutomationCredential -AutomationAccountName $AutomationName -ResourceGroupName $ResourceGroupMisc -Name "$($ResourceGroupApp)||$AccountName" -Value $cred
}