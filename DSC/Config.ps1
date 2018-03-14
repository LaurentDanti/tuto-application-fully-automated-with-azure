
Configuration Config {
    Param (
        [Parameter(Mandatory = $true)]
        [string]
        $URLRepo,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        [Parameter(Mandatory = $true)]
        [string]
        $Version,

        [Parameter()]
        [string]
        $Temp = 'C:\Windows\Temp',

        [Parameter()]
        [string]
        $InitMem = 'default',

        [Parameter()]
        [string]
        $MaxMem = 'default',

        [Parameter()]
        [string]
        $Thread = 'default'
    )

  
    Import-DSCResource -ModuleName 'xPSDesiredStateConfiguration' -ModuleVersion '6.0.0.0'
    
    switch ($Version) {
        '3.3.1' {
            $sourceneo4j    = "neo4j-community-$Version-windows.zip"
            $VersionJdk     = "8u112"
        }
    }

    # The way to get a product id from a package already install
    # Get-WmiObject win32_product | Where-Object Name -Like "*Java*" | Format-table identifyingNumber, name, version
    # {26A24AE4-039D-4CA4-87B4-2F64180112F0} Java 8 Update 112 (64-bit)                    8.0.1120.15
    # {64A3A4F4-B792-11D6-A78A-00B0D0180112} Java SE Development Kit 8 Update 112 (64-bit) 8.0.1120.15  
    
    $Pathjdk = "C:\jdk\"           
    switch ($VersionJdk) {
        '8u112' {
            $namejdk       = 'Java SE Development Kit 8 Update 112 (64-bit)'
            $sourcejdk  = 'jdk-8u112-windows-x64.exe'
            $productID  = '64A3A4F4-B792-11D6-A78A-00B0D0180112'
        }
        '7u80' {
            $namejdk      = 'Java SE Development Kit 7 Update 80 (64-bit)'
            $sourcejdk = 'jdk-7u80-windows-x64.exe'
            $productID = '64A3A4F4-B792-11D6-A78A-00B0D0170800'
        }
    }
    
    $featureList = @('ToolsFeature','PublicjreFeature') 
    $arguments = "/s INSTALLDIR=""$Pathjdk"" ADDLOCAL=""$($featureList -join ',')"""

    Node $AllNodes.NodeName
    {

        # Get password in DSC configuration from automation crendetial
        $Password             = $(Get-AutomationPSCredential -Name $Node.Neo4jUser).GetNetworkCredential().password

        # Neo4j Community dont allow multinode scale 
        # So $Node.master and $Node.slave are not really use here but we have use WaitForAll to synchronise config between nodes just for fun
        $serverMaster           = ($AllNodes.Where({$_.Master -eq $true}).NodeName)
        if( $Node.Master -eq $false ) {
            WaitForAll WaitInstallMaster
            {
                ResourceName      = "[Service]StartNeo4j"
                NodeName          = $serverMaster
                RetryIntervalSec  = 40
                RetryCount        = 60
                #PsDscRunAsCredential = $CredServer
            }
            $dependPrimary  =   "[WaitForAll]WaitInstallMaster"
        }
        else {
            #primary node
            $dependPrimary  =   @()
        }

        xRemoteFile Neo4jDL {
            Uri             = "$URLRepo/$sourceneo4j"
            DestinationPath = Join-path -Path $Temp -ChildPath $sourceneo4j
            MatchSource     = $False
        }
    
        xArchive Neo4jUnzip {
            DependsOn   = '[xRemoteFile]Neo4jDL'
            Path        = Join-path -Path $Temp -ChildPath $sourceneo4j
            Destination = $Path
            Ensure      = 'Present'
        }
    
        xRemoteFile JdkDL {
            DependsOn       = '[xRemoteFile]Neo4jDL'
            Uri             = "$URLRepo/$sourcejdk"
            DestinationPath = Join-path $Temp $sourcejdk
            MatchSource     = $False
        }

        Log LogExample
        {
            Message = "$namejdk "
        }
    
        Package InstallJdk {
            DependsOn = "[xRemoteFile]JdkDL"
            Ensure    = "Present"
            Name      = $namejdk
            Path      = Join-path -Path $Temp -ChildPath $sourcejdk
            Arguments = $arguments
            ProductId = $productID
        }
    
        xEnvironment PathJavaHome {
            DependsOn = "[Package]InstallJdk"
            Name      = "JAVA_HOME"
            Value     = "$Pathjdk"
            Ensure    = "Present"
        }
    
        xEnvironment PathJava {
            DependsOn   = '[xEnvironment]PathJavaHome'
            Name        = "PATH"
            Value       = "$Pathjdk\bin"
            Path        = $true
            Ensure      = 'Present'
        }

        #Import-Module E:\Softs\neo4j\neo4j-community-3.1.1\bin\Neo4j-Management.psd1
        Script InstallNeo4j {
            DependsOn = '[xArchive]Neo4jUnzip','[xEnvironment]PathJava',$dependPrimary

            SetScript = {
                Import-Module "$Using:Path\neo4j-community-$Using:version\bin\Neo4j-Management.psd1"
                $confPath   = "$Using:Path\neo4j-community-$Using:version\conf\neo4j.conf"

                Write-Verbose 'Installing neo4j'
                Invoke-Neo4j install-service -Verbose

                Write-Verbose 'Set password'
                Invoke-Neo4jAdmin set-initial-password "$Using:Password"
                $confContent = Get-Content -Path $confPath
                $confContent = $confContent -replace ".*dbms\.connectors\.default_advertised_address.*", "dbms.connectors.default_advertised_address=$env:COMPUTERNAME"
                $confContent = $confContent -replace ".*dbms\.connectors\.default_listen_address.*", "dbms.connectors.default_listen_address=$env:COMPUTERNAME"
                $confContent | Set-Content -Path $confPath
            }

            TestScript = {
                Import-Module "$Using:Path\neo4j-community-$Using:version\bin\Neo4j-Management.psd1"
                if (((Invoke-Neo4j status -Verbose) -eq 3 ) -and (-not (Get-Service -Name neo4j -ErrorAction Ignore))) {
                    Write-Verbose 'Neo4j not installed'
                    return $false
                }
                else {
                    return $true
                }
            }

            GetScript = {
                return @{}
            }
        }

        Script ConfigNeo4j {
            DependsOn = '[Script]InstallNeo4j'
            SetScript = {
                Import-Module "$Using:Path\neo4j-community-$Using:version\bin\Neo4j-Management.psd1"
                $confPath       = "$Using:Path\neo4j-community-$Using:version\conf\neo4j.conf"
                $confContent    = Get-Content -Path $confPath
                if ($Using:initmem -ne "default") {
                    $confContent = $confContent -replace ".*dbms\.memory\.heap\.initial_size.*", "dbms.memory.heap.initial_size=$Using:initmem"
                }

                if ($Using:maxmem -ne "default") {
                    $confContent = $confContent -replace ".*dbms\.memory\.heap\.max_size.*", "dbms.memory.heap.max_size=$Using:maxmem"
                }

                if ($Using:thread -ne "default") {
                    $confContent = $confContent -replace ".*dbms\.threads\.worker_count.*", "dbms.threads.worker_count=$Using:thread"
                }

                $confContent | Set-Content $confPath
                Invoke-Neo4j restart
            }

            TestScript = {
                if (($Using:initmem -eq "default") -and ($Using:maxmem -eq "default") -and ($Using:thread -eq "default")) {
                    Write-Verbose 'Neo4j configuration not needed'
                    return $true
                }
                else {
                    if ((select-string "^dbms.memory.heap.initial_size=$Using:initmem" -Path $Conf) -and `
                        (select-string "^dbms.memory.heap.max_size=$Using:maxmem" -Path $Conf) -and `
                        (select-string "^dbms.threads.worker_count=$Using:thread" -Path $Conf)
                        ) {
                        Write-Verbose 'Neo4j configuration not needed'
                        return $true
                    }
                    else {
                        Write-Verbose 'Neo4j configuration needed'
                        return $false
                    }
                }
            }

            GetScript = {
                return @{}
            }
        }

        Service StartNeo4j {
            DependsOn = "[Script]ConfigNeo4j"
            Name      = "neo4j"
            State     = "Running"
            Ensure    = "Present"
        }

        #use xfirewall to allow 7474 to come
        #this disable all the firewall
        Script DisableFirewall 
        {
            GetScript = {
                @{
                    GetScript   = $GetScript
                    SetScript   = $SetScript
                    TestScript  = $TestScript
                    Result      = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }

            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }

            TestScript = {
                $Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                $Status -eq $True
            }
        }
    }
    
}