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
$ixAppPluginManager load "RTSP"

#
# setup logger
#
set logtag "IxLoad-api"
set logName "simplertspclientandserver"
set logger [::IxLoad new ixLogger $logtag 1]
set logEngine [$logger getEngine]
$logEngine setLevels $::ixLogger(kLevelDebug) $::ixLogger(kLevelInfo)
$logEngine setFile $logName 2 256 1


#-----------------------------------------------------------------------
# Build Chassis Chain
#-----------------------------------------------------------------------
set chassisChain [::IxLoad new ixChassisChain]
$chassisChain addChassis $::IxLoadPrivate::SimpleSettings::chassisName


#-----------------------------------------------------------------------
# Build client and server Network
#-----------------------------------------------------------------------

set clnt_network [::IxLoad new ixNetworkGroup $chassisChain]
$clnt_network config \
	-name                                    "clnt_network" 

$clnt_network globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $GratArp

$GratArp config \
	-enabled                                 true \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $TCP

$TCP config \
	-tcp_tw_recycle                          true \
	-tcp_keepalive_time                      75 \
	-tcp_keepalive_intvl                     7200 \
	-tcp_wmem_default                        4096 \
	-tcp_port_min                            1024 \
	-tcp_port_max                            65535 \
	-tcp_window_scaling                      false \
	-name                                    "TCP" \
	-tcp_rmem_default                        4096 

set DNS [::IxLoad new ixNetDnsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$clnt_network globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_1 [$clnt_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config 

$Ethernet__PHY_1 config \
	-name                                    "Ethernet /PHY-1" \
	-cardElm                                 $my_ixNetEthernetELMPlugin 

$Ethernet__PHY_1 childrenList.clear

set MAC_VLAN_1 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet__PHY_1 childrenList.appendItem -object $MAC_VLAN_1

$MAC_VLAN_1 config \
	-name                                    "MAC/VLAN-1" 

$MAC_VLAN_1 childrenList.clear

set IP_1 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_1 childrenList.appendItem -object $IP_1

$IP_1 config \
	-name                                    "IP-1" 

$IP_1 childrenList.clear

$IP_1 extensionList.clear

$MAC_VLAN_1 extensionList.clear

$Ethernet__PHY_1 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_1 rangeList.clear

set ip_1 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured!
$IP_1 rangeList.appendItem -object $ip_1

$ip_1 config \
	-count                                   100 \
	-name                                    "ip-1" \
	-gatewayAddress                          "0.0.0.0" \
	-autoMacGeneration                       true \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.2.1" 

set mac_1 [$ip_1 getLowerRelatedRange "MacRange"]

$mac_1 config \
	-count                                   100 \
	-mac                                     "00:C6:12:02:01:00" \
	-name                                    "mac-1" 

set vlan_1 [$ip_1 getLowerRelatedRange "VlanIdRange"]

$vlan_1 config \
	-name                                    "vlan-1" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


$clnt_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::clientPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::clientPort(PORT_ID)


set svr_network [::IxLoad new ixNetworkGroup $chassisChain]
$svr_network config \
	-name                                    "svr_network" 

$svr_network globalPlugins.clear

set Filter [::IxLoad new ixNetFilterPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Filter

$Filter config \
	-name                                    "Filter" 

set GratArp [::IxLoad new ixNetGratArpPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $GratArp

$GratArp config \
	-enabled                                 true \
	-name                                    "GratArp" 

set TCP [::IxLoad new ixNetTCPPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $TCP

$TCP config \
	-tcp_tw_recycle                          true \
	-tcp_keepalive_time                      75 \
	-tcp_keepalive_intvl                     7200 \
	-tcp_wmem_default                        4096 \
	-tcp_port_min                            1024 \
	-tcp_port_max                            65535 \
	-tcp_window_scaling                      false \
	-name                                    "TCP" \
	-tcp_rmem_default                        4096 

set DNS [::IxLoad new ixNetDnsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $DNS

$DNS config \
	-name                                    "DNS" 

$DNS hostList.clear

$DNS searchList.clear

$DNS nameServerList.clear

set Settings [::IxLoad new ixNetIxLoadSettingsPlugin]
# ixNet objects needs to be added in the list before they are configured!
$svr_network globalPlugins.appendItem -object $Settings

$Settings config \
	-name                                    "Settings" 

set Ethernet__PHY_2 [$svr_network getL1Plugin]

set my_ixNetEthernetELMPlugin [::IxLoad new ixNetEthernetELMPlugin]
$my_ixNetEthernetELMPlugin config 

$Ethernet__PHY_2 config \
	-name                                    "Ethernet /PHY-2" \
	-cardElm                                 $my_ixNetEthernetELMPlugin 

$Ethernet__PHY_2 childrenList.clear

set MAC_VLAN_2 [::IxLoad new ixNetL2EthernetPlugin]
# ixNet objects needs to be added in the list before they are configured!
$Ethernet__PHY_2 childrenList.appendItem -object $MAC_VLAN_2

$MAC_VLAN_2 config \
	-name                                    "MAC/VLAN-2" 

$MAC_VLAN_2 childrenList.clear

set IP_2 [::IxLoad new ixNetIpV4V6Plugin]
# ixNet objects needs to be added in the list before they are configured!
$MAC_VLAN_2 childrenList.appendItem -object $IP_2

$IP_2 config \
	-name                                    "IP-2" 

$IP_2 childrenList.clear

$IP_2 extensionList.clear

$MAC_VLAN_2 extensionList.clear

$Ethernet__PHY_2 extensionList.clear

#################################################
# Setting the ranges starting with the plugin on top of the stack
#################################################
$IP_2 rangeList.clear

set ip_2 [::IxLoad new ixNetIpV4V6Range]
# ixNet objects needs to be added in the list before they are configured!
$IP_2 rangeList.appendItem -object $ip_2

$ip_2 config \
	-name                                    "ip-2" \
	-gatewayAddress                          "0.0.0.0" \
	-prefix                                  16 \
	-mss                                     100 \
	-ipAddress                               "198.18.200.1" 

set mac_2 [$ip_2 getLowerRelatedRange "MacRange"]

$mac_2 config \
	-mac                                     "00:C6:12:02:02:00" \
	-name                                    "mac-2" 

set vlan_2 [$ip_2 getLowerRelatedRange "VlanIdRange"]

$vlan_2 config \
	-name                                    "vlan-2" \
	-idIncrMode                              1 \
	-priority                                0 \
	-innerPriority                           0 


$svr_network portList.appendItem \
    -chassisId  1 \
    -cardId     $::IxLoadPrivate::SimpleSettings::serverPort(CARD_ID)\
    -portId     $::IxLoadPrivate::SimpleSettings::serverPort(PORT_ID)


#-----------------------------------------------------------------------
# Construct Client Traffic
#-----------------------------------------------------------------------
set expected "clnt_traffic"
set clnt_traffic [::IxLoad new ixClientTraffic -name $expected]

$clnt_traffic agentList.appendItem \
    -name               "my_rtsp_client" \
    -protocol           "RTSP" \
    -type               "Client" \
    -commandTimeout     60 \
    -rtpTransport       $::RTSP_Client(kRtpTransportUdp)

$clnt_traffic agentList(0).commandList.appendItem \
    -command        "{PlayMedia}" \
    -destination    "svr_traffic_my_rtsp_server:554" \
    -media          "/test1.mp3" \
    -arguments      "PLAY_TILL_END"
    
$clnt_traffic agentList(0).rtspHeaders.config \
    -clientEmulation  $::RtspHeaders(kClientEmulationTypeCustom)
$clnt_traffic agentList(0).rtspHeaders.list.appendItem \
    -name   "User-Agent" \
    -value  "QTS(qtver=6.5)"


#-----------------------------------------------------------------------
# Construct Server Traffic
#-----------------------------------------------------------------------
set expected "svr_traffic"
set svr_traffic [::IxLoad new ixServerTraffic -name $expected]
set actual [$svr_traffic cget -name]

$svr_traffic agentList.appendItem \
    -name               "my_rtsp_server" \
    -protocol           "RTSP" \
    -type               "Server" \
    -serverEmulation    $::RTSP_Server(kServerEmulationQuickTime) \
    -port               554 \
    -commandTimeout     60 


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
    -name           "my_test" \
    -statsRequired  0 
]

$test clientCommunityList.appendItem -object $clnt_t_n_mapping
$test serverCommunityList.appendItem -object $svr_t_n_mapping


#-----------------------------------------------------------------------
# Create a test controller bound to the previosuly allocated
# chassis chain. This will eventually run the test we created earlier.
#-----------------------------------------------------------------------
set testController [::IxLoad new ixTestController -outputDir 1]

$testController setResultDir "[pwd]/RESULTS/simplertspclientandserver"

$testController run $test

vwait ::ixTestControllerMonitor
puts $::ixTestControllerMonitor

 
#-----------------------------------------------------------------------
# Cleanup
#-----------------------------------------------------------------------

$testController releaseConfigWaitFinish

::IxLoad delete $logger
::IxLoad delete $logEngine
::IxLoad delete $chassisChain
::IxLoad delete $clnt_network
::IxLoad delete $svr_network
::IxLoad delete $clnt_traffic
::IxLoad delete $svr_traffic
::IxLoad delete $clnt_t_n_mapping
::IxLoad delete $svr_t_n_mapping
::IxLoad delete $test
::IxLoad delete $testController


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

