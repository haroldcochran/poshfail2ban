### Pre-build the vars, arrays, and regular expression
$workLoc = #Set the location to run the script at
$logFile = #Set the location and file for the poshFail2Ban log
$fwRule = "poshFail2Ban"
$trafficArr = @()
$ipArry = @()
$regex = [regex] "\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
$blockedIPs = @((Get-NetFirewallRule -DisplayName "poshFail2Ban" | Get-NetFirewallAddressFilter).RemoteAddress)

### Move to logging location
Set-Location $workLoc

### Find the failures in the log
foreach ($line in (Get-Content (ls -Name localhost_access* | Select -Last 1)))
    {
        IF ($line -like "*404*"){$trafficArr += $line}
    }

### Extract the ip addresses
foreach ($i in $trafficArr)
    {
        $ipArry += ($regex.Matches($i) | %{$_.Value})
    }

### Check the failure count and record into banlist 
foreach ($ip in ($ipArry | Select -Unique))
    {
        $ipCount = Select-String -InputObject $ipArry -Pattern $ip -AllMatches
        IF (($ipCount.Matches.Count) -gt 9)
            {
                IF ($blockedIPs -contains $ip)
                    {
                        $NULL
                        BREAK
                    }
                ELSE
                    {
                        $ip | Out-File $logFile -Append
						$blockedIPs += $ip
						Set-NetFirewallRule -DisplayName $fwRule -RemoteAddress $blockedIPs
                    }
            }
    }