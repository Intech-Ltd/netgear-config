<#

.SYNOPSIS
    Creates switch configuration files for Netgear GS324T switches.

.DESCRIPTION
    The script accepts parameters, or will prompt for them if absent. It creates
    configuration files based on these settings, for use in EPCS LANs.

    The file will be saved with a name based on the profit centre and switch
    number.

.PARAMETER LANIP

    The IP address of the LAN (e.g. "10.1.57.0"). The final octet is discarded.

.PARAMETER SwitchNumber

    The number of the switch within the network, between 1 and 9.

.PARAMETER ProfitCentre

    Name of destination Profit Centre (e.g. 940E-DARTFORD).

.COMPONENT
    EPCS

.EXAMPLE
    If PowerShell script execution is permitted, from a PowerShell prompt:

      .\New-SwitchConfig.ps1

    This will prompt for all parameters. Alternatively, specify parameters thus:

      .\New-SwitchConfig.ps1 -LANIP "10.1.57.0" -SwitchNumber 1 -ProfitCentre 940E-DARTFORD

    The script can easily be automated by a calling script (based, for example
    upon a CSV containing all the required parameters).

.NOTES
    This release:

        Version: 0.1 [Set also in the $Version variable]
        Date:    24 October 2022
        Author:  Rob Pomeroy
        Company: Intech Ltd for Edmundson Electrical

    Version history:

        0.1 - 24 October 2022 - testing

#>
##############
# PARAMETERS #
##############
Param(
    [Parameter(Position = 0)][string]$LANIP,       # LAN without CIDR mask
    [Parameter(Position = 1)][int]$SwitchNumber,   # From 1 to 9
    [Parameter(Position = 2)][string]$ProfitCentre # Profit Centre name
)


#############
# FUNCTIONS #
#############
. "$PSScriptRoot\Functions.ps1"


##############
# VALIDATION #
##############

# Check if LANIP passed as parameter, and if so, if it is valid
if($PSBoundParameters.ContainsKey('LANIP')) {
    $LANIP = Test-IP -LANIP $LANIP
}
# Prompt for IP, if required
while($null -eq $LANIP -or $LANIP -eq '') {
    $LANIP = (Read-Host -Prompt "Enter the profit centre LAN IP (e.g. 10.1.57.0)").Trim()
    $LANIP = Test-IP -LANIP $LANIP
}
$Network = ($LANIP  -Replace "\.[^.]*$", ".")
Write-Host "Network prefix is $Network"

if($PSBoundParameters.ContainsKey('SwitchNumber')) {
    $SwitchNumber = Test-SwitchNumber -SwitchNumber $SwitchNumber
}
# Prompt for switch number, if required
while($null -eq $SwitchNumber -or $SwitchNumber -eq '') {
    $StringInput = (Read-Host -Prompt "Enter the number of the switch (1-9)").Trim()
    $SwitchNumber = Test-SwitchNumber -SwitchNumber $StringInput
}
Write-Host "Switch number is $SwitchNumber"

# Prompt for Profit Centre, if required
while($null -eq $ProfitCentre -or $ProfitCentre -eq '') {
    $ProfitCentre = (Read-Host -Prompt "Enter the profit centre name (e.g. 940E-DARTFORD)").Trim()
}

# Strip invalid characters from the profit centre name and convert to uppercase
$ProfitCentre = ($ProfitCentre -replace '[^a-zA-Z0-9\-_]', '').ToUpper()
Write-Host "Profit centre is $ProfitCentre"


#################
# CREATE CONFIG #
#################

$config = @"
0x4e470x010x00GS3XXTX             1.0.0.43            0x000000000x00000000000000
! The line above is the NSDP Text Configuration header. DO NOT EDIT THIS HEADER
!Current Configuration:
!
!System Description "GS324T S350 Series 24-Port Gigabit Ethernet Smart Managed Pro Switch with 2 SFP Ports"
!System Software Version "1.0.0.43"
!System Up Time          "0 days 0 hrs 34 mins 21 secs"
!Additional Packages     QOS
!Current SNTP Synchronized Time: SNTP Last Attempt Status Is Not Successful
!
network protocol none
network parms $($Network)2$SwitchNumber 255.255.255.0 $($Network)1
vlan database
exit
ip http session soft-timeout 30
ip http secure-server
ip http secure-session soft-timeout 30
configure
sntp client mode unicast
sntp server "$($Network)100"
clock summer-time recurring EU offset 60 zone "BST"
auto-dos
dos-control firstfrag
dos-control icmpv4
dos-control icmpv6
dos-control icmpfrag
dos-control sipdip
dos-control smacdmac
dos-control tcpfinurgpsh
dos-control tcpflagseq
dos-control tcpsyn
dos-control tcpsynfin
dos-control tcpfrag
dos-control tcpoffset
ip domain name "switch$($SwitchNumber).$ProfitCentre.epcs-wan.eel.co.uk"
ip name server $($Network)100
username "admin" password `$6`$SyikKK/HSmICwMD6`$N65AtJZPLMppXXizdJpRYE44y3HTCo78vQAnBAKdAF8lSMXmBT8JBWCUZAczxppoTeBytrqkPiqhDwvO7dAAD1 encryption-type sha512 level 15 encrypted
line console
serial timeout 0
exit
line telnet
exit
snmp-server sysname "Switch $($SwitchNumber)"
snmp-server location "$ProfitCentre"
!
snmp-server community "servicecentre"
snmp-server community ipaddr 10.12.0.0 servicecentre
snmp-server community ipmask 255.255.0.0 servicecentre
snmp-server community "intech"
snmp-server community ipaddr 207.13.251.0 intech
snmp-server community ipmask 255.255.255.0 intech
snmp-server user "admin" DefaultWrite auth-sha512-key 5e00d5ffdd6995ee6dbc4c21a48a813b942e487f147f4de13d04906060304b500f423026a1fe672e9edbb3de56345cd2ec6e8c5922afbd6562b6485d6f490026 priv-aes128-key 5e00d5ffdd6995ee6dbc4c21a48a813b942e487f147f4de13d04906060304b500f423026a1fe672e9edbb3de56345cd2ec6e8c5922afbd6562b6485d6f490026
access-list 1 permit $($Network)0 255.255.255.0
interface g1
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
exit
interface g2
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g3
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g4
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g5
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g6
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g7
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g8
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g9
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g10
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g11
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g12
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g13
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g14
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g15
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g16
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g17
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g18
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g19
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g20
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g21
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g22
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g23
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g24
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g25
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
interface g26
port-security
port-security max-dynamic 2
port-security max-static 2
port-security violation shutdown
ip access-group 1 in 1
exit
!Management ACAL
management access-list "ProfitCentre"
permit ip-source $($Network)0 mask 255.255.255.0 service https priority 1
permit ip-source $($Network)0 mask 255.255.255.0 service http priority 2
permit ip-source 10.12.0.0 mask 255.255.0.0 service https priority 4
permit ip-source 10.12.0.0 mask 255.255.0.0 service http priority 5
permit ip-source 10.12.0.0 mask 255.255.0.0 service snmp priority 6
permit ip-source 207.13.251.0 mask 255.255.255.0 service https priority 7
permit ip-source 207.13.251.0 mask 255.255.255.0 service http priority 8
permit ip-source 207.13.251.0 mask 255.255.255.0 service snmp priority 9
exit
management access-class "ProfitCentre"
exit

"@


###############
# SAVE CONFIG #
###############

# Check if configs directory exists and if not, create it
$configsDir = "$PWD\configs"
if (!(Test-Path -Path $configsDir)) {
    New-Item -ItemType Directory -Path $configsDir | Out-Null
}

# Derive filename
$filename = "$configsDir\$ProfitCentre-#$SwitchNumber-conf"

# Save as UTF-8 file with Unix-style line endings, no BOM
$config = $config -replace "`r`n", "`n"
$writer = [IO.StreamWriter]::new($filename, $false)
$writer.Write($config)
$writer.Close()

Write-Host "Config file saved as $filename"