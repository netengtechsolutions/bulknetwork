
param( [Parameter()][string]$ping )

$HQ_IPv4 = "10.1.20.254","10.1.21.254","10.1.25.254","10.1.50.254","10.1.150.254"
$MP_IPv4 = "10.2.20.254","10.2.21.254","10.2.25.254","10.2.50.254","10.2.125.254","10.2.150.254"
$HQ_IPv6 = "2620:fc:0:d358:50::50","2620:fc:0:d358:100:de0e:cda7:dd59","2620:fc:0:d358:150::150" 
$MP_IPv6 = "2620:fc:0:d369:50::50","2620:fc:0:d369:100:22b:91fe:cd93","2620:fc:0:d369:150::150"
$hosts = ''
while ($hosts -eq '') {
    $selection = Read-Host '
    1) $HQ_IPv4 = "10.1.20.254","10.1.21.254","10.1.25.254","10.1.50.254","10.1.150.254"
    2) $MP_IPv4 = "10.2.20.254","10.2.21.254","10.2.25.254","10.2.50.254","10.2.125.254","10.2.150.254"
    3) $HQ_IPv6 = "2620:fc:0:d358:50::50","2620:fc:0:d358:100:d115:dc97:313b","2620:fc:0:d358:150::150" 
    4) $MP_IPv6 = "2620:fc:0:d369:50::50","2620:fc:0:d369:100::1","2620:fc:0:d369:150::150"
    '
    if ($selection -eq 1) { $hosts = $HQ_IPv4 }
    elseif ($selection -eq 2) { $hosts = $MP_IPv4 }
    elseif ($selection -eq 3) { $hosts = $HQ_IPv6 }
    elseif ($selection -eq 4) { $hosts = $MP_IPv6 }
}




while ($true) {
    foreach ($IP in $hosts) { 
        if (test-connection $IP -count 1 -Quiet)
            { Write-Host -ForegroundColor Green "Ping success on $IP" }
            else { Write-Host -ForegroundColor Red "Ping Failed on $IP" }
        Start-Sleep -Milliseconds 100
    }
}
