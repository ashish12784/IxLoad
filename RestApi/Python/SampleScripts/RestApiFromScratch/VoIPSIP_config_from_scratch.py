import Utils.IxLoadUtils as IxLoadUtils
import Utils.IxRestUtils as IxRestUtils
import inspect, os

####TEST CONFIG

kGatewayServer = "127.0.0.1"
kGatewayPort = 8443
kIxLoadVersion = "8.40.0.272"#TODO - to be changed by user

kChassisList = ['chassisIpOrHostName']#TODO - to be changed by user

kPortListPerCommunityCommunity =    {
                                        "Traffic1@Network1" : [(1,1,11)],
                                        "Traffic2@Network2" : [(1,1,12)]
                                    }

kStatsToDisplayDict =   {
                            #format: { statSource : [stat name list] }
                            "RTP(VoIPSip)": ["Successful Records", "Functions Disconnected"],
                            "Flow(VoIPSip)": ["Successful Channels", "Active Channels"]
                        }

kCommunities = [
    # format: {option1: value1, option2: value2}
    {},  # default community with no options
    {"tcpAccelerationAllowedFlag": True}  # community with tcpAccelerationAllowedFlag set to True
]

kActivities = {
    # format: {communityName: [activityProtocolAndType1, activityProtocolAndType2]}
    'Traffic1@Network1': ['VoIP Peer'],
    'Traffic2@Network2': ['VoIP Peer']
}


def getRxfName():
    relativeFileNamePath = inspect.getfile(inspect.currentframe())
    fileName = os.path.split(relativeFileNamePath)[-1]
    fileNameWithoutExtension = fileName.split('.')[0]
    rxfName = "%s.rxf" % (fileNameWithoutExtension)

    rxfDirPath = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))

    return os.path.join(rxfDirPath, rxfName)
################


#create a connection to the gateway
connection = IxRestUtils.getConnection(kGatewayServer, kGatewayPort)

sessionUrl = None

try:
    # create a session
    IxLoadUtils.log("Creating a new session...")
    sessionUrl = IxLoadUtils.createSession(connection, kIxLoadVersion)
    IxLoadUtils.log("Session created.")

    # create nettraffics (communities)
    IxLoadUtils.log('Creating communities...')
    IxLoadUtils.addCommunities(connection, sessionUrl, kCommunities)
    IxLoadUtils.log('Communities created.')

    # create activities
    IxLoadUtils.log('Creating activities...')
    IxLoadUtils.addActivities(connection, sessionUrl, kActivities)
    IxLoadUtils.log('Activities created.')

    IxLoadUtils.log('Editing scenario settings on VoIPSIP peers...')
    rootFolder = os.path.split(getRxfName())[0]
    tstFilePath = os.path.join(rootFolder, 'TestScenario1.tst') # TODO - this will have to be edited by the user
    voipsipCommandOptions = {"scenarioFile": tstFilePath}
    IxLoadUtils.VoipPeerUtils.changeScenarioSettings(connection, sessionUrl, 'Traffic1@Network1', 'VoIPSipPeer2', voipsipCommandOptions)
    IxLoadUtils.VoipPeerUtils.changeScenarioSettings(connection, sessionUrl, 'Traffic2@Network2', 'VoIPSipPeer1', voipsipCommandOptions)

    IxLoadUtils.log("Clearing chassis list...")
    IxLoadUtils.clearChassisList(connection, sessionUrl)
    IxLoadUtils.log("Chassis list cleared.")

    IxLoadUtils.log("Adding chassis %s..." % (kChassisList))
    IxLoadUtils.addChassisList(connection, sessionUrl, kChassisList)
    IxLoadUtils.log("Chassis added.")

    IxLoadUtils.log("Assigning new ports...")
    IxLoadUtils.assignPorts(connection, sessionUrl, kPortListPerCommunityCommunity)
    IxLoadUtils.log("Ports assigned.")

    IxLoadUtils.log("Saving repository %s..." % (getRxfName()))
    IxLoadUtils.saveRxf(connection, sessionUrl, getRxfName())
    IxLoadUtils.log("Repository saved.")

    IxLoadUtils.log("Starting the test...")
    IxLoadUtils.runTest(connection, sessionUrl)
    IxLoadUtils.log("Test started.")

    IxLoadUtils.log("Polling values for stats %s..." % (kStatsToDisplayDict))
    IxLoadUtils.pollStats(connection, sessionUrl, kStatsToDisplayDict)

    IxLoadUtils.log("Test finished.")

    IxLoadUtils.log("Checking test status...")
    testRunError = IxLoadUtils.getTestRunError(connection, sessionUrl)
    if testRunError:
        IxLoadUtils.log("The test exited with the following error: %s" % testRunError)
    else:
        IxLoadUtils.log("The test completed successfully.")

    IxLoadUtils.log("Waiting for test to clean up and reach 'Unconfigured' state...")
    IxLoadUtils.waitForTestToReachUnconfiguredState(connection, sessionUrl)
    IxLoadUtils.log("Test is back in 'Unconfigured' state.")
finally:
    if sessionUrl is not None:
        IxLoadUtils.log("Closing IxLoad session...")
        IxLoadUtils.deleteSession(connection, sessionUrl)
        IxLoadUtils.log("IxLoad session closed.")
