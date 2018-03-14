Param(
    [String]
    $dnsName
)

Describe "HealthCheck" {
    
        Context "simple" {
    
            BeforeAll {
            }
                
                   
            It "Portal Neo4j here : http://$dnsName.westeurope.cloudapp.azure.com/browser/index.html" {
                    $(try {
                    Invoke-WebRequest -Uri "http://$dnsName.westeurope.cloudapp.azure.com/browser/index.html" -UseBasicParsing 
                    throw "ERROR"
                    }
                    catch {
                        if ($_.Exception.Response) {
                        $result = $_.Exception.Response.GetResponseStream()
                        $reader = New-Object System.IO.StreamReader($result)
                        $reader.BaseStream.Position = 0
                        $reader.DiscardBufferedData()
                        $reader.ReadToEnd()
                        }
                    } )| Should BeLike "*Neo4j Browser*" 
                } 
            }
        }

