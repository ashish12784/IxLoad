#
# setup path and load IxLoad package
#

source ../setup_simple.tcl

#
# Initialize IxLoad
#

# IxLoad onnect should always be called, even for local scripts
::IxLoad connect $::IxLoadPrivate::SimpleSettings::remoteServer

# once we've connected, make sure we disconnect, even if there's a problem
if [catch {

#
# Loads plugins for specific protocols configured in this test
#
global ixAppPluginManager
$ixAppPluginManager load "HTTP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simplessl_httpclientandserver"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1


#-----------------------------------------------------------------------
# package require the stat collection utilities
#-----------------------------------------------------------------------
package require statCollectorUtils
set scu_version [package require statCollectorUtils]
puts "statCollectorUtils package version = $scu_version"


#-----------------------------------------------------------------------
# Build Chassis Chain
#-----------------------------------------------------------------------
set chassisChain [::IxLoad new ixChassisChain]
$chassisChain addChassis $::IxLoadPrivate::SimpleSettings::chassisName


#-----------------------------------------------------------------------
# Build client and server Network
#-----------------------------------------------------------------------
set clnt_network [::IxLoad new ixClientNetwork $chassisChain]
$clnt_network config -name "clnt_network"
$clnt_network networkRangeList.appendItem \
    -name           "clnt_range" \
    -enable         1 \
    -firstIp        "198.18.2.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        100 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0" \
    -firstMac       "00:C6:12:02:01:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

$clnt_network arpSettings.config -gratuitousArp 0

$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)

set svr_network [::IxLoad new ixServerNetwork $chassisChain]
$svr_network config -name "svr_network"
$svr_network networkRangeList.appendItem \
    -name           "svr_range" \
    -enable         1 \
    -firstIp        "198.18.200.1" \
    -ipIncrStep     $::ixNetworkRange(kIpIncrOctetForth) \
    -ipCount        1 \
    -networkMask    "255.255.0.0" \
    -gateway        "0.0.0.0"\
    -firstMac       "00:C6:12:02:02:00" \
    -macIncrStep    $::ixNetworkRange(kMacIncrOctetSixth) \
    -vlanEnable     0 \
    -vlanId         1 \
    -mssEnable      0 \
    -mss            100

$svr_network arpSettings.config -gratuitousArp 0

# Add port to server network
$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# SSL Key & Certficate
set Secured_DSA_privateKeyPassword "ixload"

set Secured_DSAdes3_cert_512 "-----BEGIN CERTIFICATE-----
MIIDPjCCAvygAwIBAgIBADAJBgcqhkjOOAQDMHsxCzAJBgNVBAYTAklOMQswCQYD
VQQIEwJXQjEMMAoGA1UEBxMDS09MMQ0wCwYDVQQKEwRJWElBMQ4wDAYDVQQLFAVF
TkdHXDEOMAwGA1UEAxMFc3VtaXQxIjAgBgkqhkiG9w0BCQEWE3N1cGFuZGFAaXhp
YWNvbS5jb20wHhcNMDYwOTAzMjAwOTQ4WhcNMjYwODI5MjAwOTQ4WjB7MQswCQYD
VQQGEwJJTjELMAkGA1UECBMCV0IxDDAKBgNVBAcTA0tPTDENMAsGA1UEChMESVhJ
QTEOMAwGA1UECxQFRU5HR1wxDjAMBgNVBAMTBXN1bWl0MSIwIAYJKoZIhvcNAQkB
FhNzdXBhbmRhQGl4aWFjb20uY29tMIHxMIGpBgcqhkjOOAQBMIGdAkEAkg3lSlUA
b5anP5Q/StjnAFxLLRimlVJonDIP2fLNj2pzEGrmYVMkAHVAPzH7VoHJlfBG0LEB
IJaUE45C3aMRLQIVALOHA3BLtsegpN8Rlsg+SBTWq3LlAkEAkNPmc0q+AjmzxbTQ
yIzjGzIvd/2zSV/5QCCogIIJPhWgueSYpZkd9G3+ynnf/QoU7MvTcTNWRjKuGob5
d061FANDAAJAWXBi0IdmygxY5MMt+Jy0Lm8UM82bK+ZxRasSZGWYKutB4/6RHisr
dwOzKnjaeWlDlrjY/3y2gZ5Mi8VMSpUWOaOB2DCB1TAdBgNVHQ4EFgQUiAWg5Sx+
zjHXkZ2uoME8gCFEG5UwgaUGA1UdIwSBnTCBmoAUiAWg5Sx+zjHXkZ2uoME8gCFE
G5Whf6R9MHsxCzAJBgNVBAYTAklOMQswCQYDVQQIEwJXQjEMMAoGA1UEBxMDS09M
MQ0wCwYDVQQKEwRJWElBMQ4wDAYDVQQLFAVFTkdHXDEOMAwGA1UEAxMFc3VtaXQx
IjAgBgkqhkiG9w0BCQEWE3N1cGFuZGFAaXhpYWNvbS5jb22CAQAwDAYDVR0TBAUw
AwEB/zAJBgcqhkjOOAQDAzEAMC4CFQCOElr11f7uaaXVQd2+B+aXzBkYxQIVAKc/
ew4Q/eQy7i4MBU5swGi/o7xT
-----END CERTIFICATE-----"

set Secured_DSAdes3_key_512 "-----BEGIN DSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,B704DF2A42F20216

26Q4nGVrMm7Tj2ECw7vq5glCsnMJM2edoI6DCAi2e+ZsgBb2A9bbRP+4AbXESHXt
SpMcf75YdN5vSriGtrxk5qZyJevLFj6m/t9nQwvfo4RlHZ5jCJjSmBkXkV1316/C
gjZrgTt2JwjNaU62DZtg2r+KfhTIfXTEeAt6I1SHr5mStCbCLryd27dR/wo2F8Bq
Mf7Bwi85dVjTlFV56wFH0h2zm0NiqkxNpMf5gvm/PIYxfC/ka/HtYPKiJc8p54F/
FslKhB+etS/M04QROWgi3QkB0hL/aYXhoMR+hG7OssuWbPCFMynoEHNf8eNYwoe0
uEflgT+dztoTOYzDaj95pg==
-----END DSA PRIVATE KEY-----"
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Construct Client Traffic
# The ActivityModel acts as a factory for creating agents which actually
# generate the test traffic
#-----------------------------------------------------------------------
set clnt_traffic [::IxLoad new ixClientTraffic -name "client_traffic"]

$clnt_traffic agentList.appendItem \
    -name                   "my_http_client" \
    -protocol               "HTTP" \
    -type                   "Client" \
    -maxSessions            3 \
    -httpVersion            $::HTTP_Client(kHttpVersion10) \
    -keepAlive              0 \
    -maxPersistentRequests  3 \
    -followHttpRedirects    0 \
    -enableCookieSupport    0 \
    -enableHttpProxy        0 \
    -enableHttpsProxy       0 \
    -browserEmulation       $::HTTP_Client(kBrowserTypeIE5) \
    -enableSsl              1 \
    -sslVersion             $::HTTP_Client(kSslVersion3) \
    -sequentialSessionReuse 2 \
    -clientCiphers          "DHE-DSS-RC4-SHA" \
    -privateKeyPassword     $Secured_DSA_privateKeyPassword \
    -privateKey             $Secured_DSAdes3_key_512 \
    -certificate            $Secured_DSAdes3_cert_512

#
# Add actions to this client agent
#
foreach {pageObject destination} {
    "/4k.htm" "svr_traffic_my_http_server"
    "/8k.htm" "svr_traffic_my_http_server"
    "/128k.htm" "svr_traffic_my_http_server"
} {
    $clnt_traffic agentList(0).actionList.appendItem  \
        -command        "GET(SSL)" \
        -destination    $destination \
        -pageObject     $pageObject
}



#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set svr_traffic [::IxLoad new ixServerTraffic -name "svr_traffic"]

$svr_traffic agentList.appendItem \
    -name       "my_http_server" \
    -protocol   "HTTP" \
    -type       "Server" \
    -acceptSslConnections   1 \
    -httpsPort              443 \
    -ServerCiphers          "DHE-DSS-RC4-SHA" \
    -enableDHsupport        1 \
    -privateKeyPassword     $Secured_DSA_privateKeyPassword \
    -privateKey             $Secured_DSAdes3_key_512 \
    -certificate            $Secured_DSAdes3_cert_512

for {set idx 0} {$idx < [$svr_traffic agentList(0).responseHeaderList.indexCount]} {incr idx} {
    set response [$svr_traffic agentList(0).responseHeaderList.getItem $idx]
    if {[$response cget -name] == "200_OK"} {
        set response200ok $response
    }
    if {[$response cget -name] == "404_PageNotFound"} {
        set response404_PageNotFound $response
    }
}

#
# Clear pre-defined web pages, add new web pages
#
$svr_traffic agentList(0).webPageList.clear

$svr_traffic agentList(0).webPageList.appendItem \
    -page           "/4k.html" \
    -payloadType    "range" \
    -payloadSize    "4096-4096" \
    -response       $response200ok

$svr_traffic agentList(0).webPageList.appendItem \
    -page           "/8k.html" \
    -payloadType    "range" \
    -payloadSize    "8192-8192" \
    -response       $response404_PageNotFound


$svr_traffic agentList(0).webPageList.appendItem \
    -page           "/128k.html" \
    -payloadType    "range" \
    -payloadSize    "131072" \
    -response       $response200ok


#-----------------------------------------------------------------------
# Create a client and server mapping and bind into the
# network and traffic that they will be employing
#-----------------------------------------------------------------------
set clnt_t_n_mapping [::IxLoad new ixClientTrafficNetworkMapping \
    -network                $clnt_network \
    -traffic                $clnt_traffic \
    -objectiveType          $::ixObjective(kObjectiveTypeSimulatedUsers) \
    -objectiveValue         20 \
    -rampUpValue            5 \
    -sustainTime            20 \
    -rampDownTime           20
]


set svr_t_n_mapping [::IxLoad new ixServerTrafficNetworkMapping \
    -network                $svr_network \
    -traffic                $svr_traffic \
    -matchClientTotalTime   1
]


#-----------------------------------------------------------------------
# Create the test and bind in the network-traffic mapping it is going
# to employ.
#-----------------------------------------------------------------------
set test [::IxLoad new ixTest \
    -name               "my_test" \
    -statsRequired      1 \
    -enableResetPorts   1
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "RESULTS/simplessl_httpclientandserver"

#-----------------------------------------------------------------------
# Set up stat Collection
#-----------------------------------------------------------------------
set NS statCollectorUtils
set ::test_server_handle [$testController getTestServerHandle]
${NS}::Initialize -testServerHandle $::test_server_handle

#
# Clear any stats that may have been registered previously
#
${NS}::ClearStats

#
# Define the stats we would like to collect
#
${NS}::AddStat \
    -caption "Watch_Stat_1" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Sent" \
    -aggregationType kSum \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_2" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Received" \
    -aggregationType kSum \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_3" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Time To Last Byte (ms)" \
    -aggregationType kWeightedAverage \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_4" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Sent" \
    -aggregationType kRate \
    -filterList {}

${NS}::AddStat \
    -caption "Watch_Stat_5" \
    -statSourceType "HTTP Client" \
    -statName "HTTP Bytes Received" \
    -aggregationType kRate \
    -filterList {}

#
# Start the collector (runs in the tcl event loop)
#
proc ::my_stat_collector_command {args} {
    puts "====================================="
    puts "INCOMING STAT RECORD >>> $args"
    puts "Len = [llength $args]"
    puts  [lindex $args 0]
    puts  [lindex $args 1]
    puts "====================================="
}
${NS}::StartCollector -command ::my_stat_collector_command

$testController run $test
#
# have the script (v)wait until the test is over
#
vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

#
# Stop the collector (running in the tcl event loop)
#
${NS}::StopCollector

#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------
$testController generateReport -detailedReport 1 -format "PDF;HTML"

$testController releaseConfigWaitFinish
::IxLoad delete $chassisChain
::IxLoad delete $clnt_network
::IxLoad delete $svr_network
::IxLoad delete $clnt_traffic
::IxLoad delete $svr_traffic
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $svr_t_n_mapping
::IxLoad delete $test
::IxLoad delete $testController
::IxLoad delete $logger
::IxLoad delete $logEngine


#-----------------------------------------------------------------------
# Disconnect
#-----------------------------------------------------------------------

}] {
    puts $errorInfo
}

#
#   Disconnect/Release application lock
#
::IxLoad disconnect
