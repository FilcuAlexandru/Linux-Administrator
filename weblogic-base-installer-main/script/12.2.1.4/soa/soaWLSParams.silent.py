import os;
import os, fileinput;
import string;
import sys
import time
from java.lang import *
from java.util import Date
from java.io import File
from java.io import FileInputStream
from java.util import Properties
from java.util import Date
from java.text import SimpleDateFormat
refconfig_dir = os.path.dirname(sys.argv[0])
localization_dir=os.path.join(refconfig_dir, "resources/localization")
if localization_dir not in sys.path:
    sys.path.insert(0, localization_dir)

from soaLocalizationUtils import *
import tempfile
import datetime



def usage():
    print '==================================================================================================================='
    print '==================================================================================================================='
    print getMessage('USAGE_INFO') %(sys.argv[0])
    print '==================================================================================================================='
    print '==================================================================================================================='
    sys.exit(0)



def loadPropsFile(propsFile):
    inStream = FileInputStream(propsFile)
    propFile = Properties()
    propFile.load(inStream)
    return propFile




def isSoaCluster():
    #serverConfig()
    cd('/')
    domainConfig()
    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()
    for app in deplymentsList:
        if app.getName().find('soa-infra') != -1:
            return true

    return false



def getDomainType():
    domainConfig()
    soaDomain=false
    osbDomain=false

    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()
    for app in deplymentsList:
        if app.getName().find('Service Bus Kernel') != -1:
            osbDomain = true
        if app.getName().find('soa-infra') != -1:
            soaDomain = true
    if osbDomain==true and soaDomain==true:
        return 3
    elif osbDomain==true:
        return 2
    elif soaDomain==true:
        return 1
    else:
        return 0




def isCluster():

    try:
        cd('/')
        servers = getRunningServerNames()
        clusterName = ''
        for server in servers:
            if server.getClusterRuntime() != None:
                return true

        return false

    except Exception, ex:

        print getMessage('ERR_GET_CLUSTER_INFO') %(str(ex.toString()))
        dumpStack()
        return false


def getAllClusterNames():
    serverConfig()
    list = []
    m = ls('/Clusters', returnMap='true')
    for token in m:
        list.append(str(token))
    return list



def getServerNames():

    try:
        cd('/')
        servers = getRunningServerNames()
        serverList = []
        for server in servers:
            #print 'Getting server names:'+ server.getName()
            serverList.append(server.getName())

        return serverList

    except Exception, ex:
        print getMessage('ERR_GET_SERVER_NAMES') % (str(ex.toString()))
        dumpStack()
        return serverList


def getNonClusterOSBDomainTarget(serverList):

    if len(serverList) == 1:
        return serverList[0]

    cd('/')
    adminServerName = get('AdminServerName')

    for server in serverList:
        if server != adminServerName and isOsbTargetServer(server):
            return server


def getNonClusterSOADomainTarget(serverList):
    if len(serverList) == 1:
        return serverList[0]

    domainConfig()
    cd('/')
    adminServerName = get('AdminServerName')

    for server in serverList:
        if server != adminServerName and isSoaTargetServer(server):
            return server


def isOsbTargetServer(serverName):
    domainConfig()
    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()
    for app in deplymentsList:
        if app.getName().find('Service Bus Kernel') != -1:
            targetList = ls(app.getName() + '/Targets', returnMap='true')
            for token in targetList:
                if serverName in targetList:
                    return true

    return false


def isSoaTargetServer(serverName):
    domainConfig()
    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()

    for app in deplymentsList:
        if app.getName().find('soa-infra') != -1:
            targetList = ls(app.getName() + '/Targets', returnMap='true')
            for token in targetList:
                if serverName in targetList:
                    return true

    return false


def getOsbClusterName(clusterNameList):
    domainConfig()
    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()
    for app in deplymentsList:
        if app.getName().find('Service Bus Kernel') != -1:
            targetList = ls(app.getName()+'/Targets', returnMap='true')
            for token in targetList:
                if token in clusterNameList:
                    return token



def getSoaClusterName(clusterNameList):
    domainConfig()
    cd('/AppDeployments')
    deplymentsList = cmo.getAppDeployments()
    for app in deplymentsList:
        if app.getName().find('soa-infra') != -1:
            targetList = ls(app.getName()+'/Targets', returnMap='true')
            for token in targetList:
                if token in clusterNameList:
                    return token


def getRunningServerNames():
    domainRuntime()
    cd('ServerRuntimes')
    servers_runtime = domainRuntimeService.getServerRuntimes()
    domainConfig()
    return servers_runtime


def getJTAProperties(domain, properties, f):
    cd(str("/JTA/" + domainName))
    curr_TimeoutSeconds = int(get('TimeoutSeconds'));
    curr_maxResourceRequests = int(get("MaxResourceRequestsOnServer"))
    print 'Current timeout:' + str(curr_TimeoutSeconds)
    print 'current maxresource requests:' + str(curr_maxResourceRequests)
    jtaTimeOut = properties.getProperty("jta.timeout.seconds")
    maxResourceRequests = properties.getProperty("jta.maxresource.requests")

def updateSOAEDNPollTimeOut(properties, f, clusterExists, targetName):
    try:
        serverNames = getRunningServerNames()
        cd('/')
        adminServerName = get('AdminServerName')
        domainRuntime()

        pollTimeOutSecName = properties.getProperty("soa.mbean.attribute.polltimeoutmillisec.name")
        pollTimeOutSecValue = properties.getProperty("soa.mbean.attribute.polltimeoutmillisec.value")
        f.write('\n\n')
        f.write('\n' + 'EDN MBean configuration ')
        for name in serverNames:
            managedServerName = name.getName()
            if managedServerName != adminServerName:
                try:
                    ednObjectName = ObjectName(
                        "oracle.as.soainfra.config:Location=" + managedServerName + ",name=edn,type=EDNConfig,Application=soa-infra")
                    attributeValue = mbs.getAttribute(ednObjectName, pollTimeOutSecName)
                    f.write('\n\n')
                    if clusterExists and name.getClusterRuntime().getName() == targetName:
                        f.write(getMessage('AUDIT_EDN_CLUSTER_CONFIGURATION_MSG') % (name.getClusterRuntime().getName()))
                    else:
                        f.write(getMessage('AUDIT_EDN_CONFIGURATION_MSG') % (managedServerName))
                    f.write('\n\n');
                    f.write(getMessage('AUDIT_EDN_ATTRIB_VALUE_CONFIG'))
                    f.write('\n')
                    f.write('-------------------')
                    f.write('\n\n')
                    f.write(getMessage('AUDIT_OLD_CONFIGURATION'))
                    f.write(str(attributeValue))
                    SOAattribute = Attribute(pollTimeOutSecName, int(pollTimeOutSecValue))
                    mbs.setAttribute(ednObjectName, SOAattribute)
                    f.write('\t')
                    f.write(getMessage('AUDIT_NEW_CONFIGURATION'))
                    f.write(str(pollTimeOutSecValue))
                    f.write('\n')
                    if clusterExists and name.getClusterRuntime().getName() == targetName:
                        break
                except java.lang.Exception, ex:
                    # ignore, EDN MBean doesnt exists in this SOA managed server and move forward
                    pass

        f.write('\n\n')
        print getMessage('EDN_CONFIG_UPDATE_SUCCESS_INFO');
        print ""

    except java.lang.Exception, ex:
        raise Exception(getMessage('ERR_EDN_CONFIG_UPDATE') % (str(ex.toString())))


def updateJTAProperties(domainName, properties, f):

    try:

        cd(str("/JTA/" + domainName))
        curr_TimeoutSeconds = int(get('TimeoutSeconds'));
        curr_maxResourceRequests=int(get("MaxResourceRequestsOnServer"))
        print ""
        print ""
        jtaTimeOut = properties.getProperty("jta.timeout.seconds")
        maxResourceRequests = properties.getProperty("jta.maxresource.requests")
        cd('/')
        edit()
        startEdit()
        cd('/JTA/' + domainName)
        cmo.setTimeoutSeconds(int(jtaTimeOut));
        cmo.setMaxResourceRequestsOnServer(int(maxResourceRequests));

        f.write('\n\n')
        f.write(getMessage('AUDIT_JTA_CONFIGURATION_MSG'))
        f.write('\n\n');
        f.write(getMessage('AUDIT_JTA_TIMEOUT_CONFIG'))
        f.write('\n')
        f.write('-------------------')
        f.write('\n\n')
        f.write(getMessage('AUDIT_OLD_CONFIGURATION'))
        f.write(str(curr_TimeoutSeconds))
        f.write('\t')
        f.write(getMessage('AUDIT_NEW_CONFIGURATION'))
        f.write(str(jtaTimeOut))
        f.write('\n\n')
        print getMessage('JTA_CONFIG_UPDATE_SUCCESS_INFO') ;
        print ""

    except java.lang.Exception, ex:
        raise Exception(getMessage('ERR_JTA_CONFIG_UPDATE') % (str(ex.toString())))




def updateExtendedLogSetting(properties,f):
    try:
       domainConfig()
       edit()
       startEdit()
       cd('/')
       managedServers = cmo.getServers()
       f.write('\n' + 'Extended Logging Format configuration ')
       format=properties.getProperty("servicebus.extended.log.format")
       elfFields=properties.getProperty("servicebus.extended.log.format.elffields")
       for managedServer in managedServers:
           serverName = managedServer.getName()
           cd('/Servers/' + serverName + '/WebServer/' + serverName + '/WebServerLog/' + serverName)
           cmo.setLogFileFormat(str(format))
           cmo.setELFFields(str(elfFields))
           f.write('\n');
           f.write(getMessage('AUDIT_EXTENDED_LOG_CONFIG_SUCCESS') % (serverName))

       print getMessage('EXTENDED_LOG_CONFIG_UPDATE_SUCCESS_INFO') ;

    except java.lang.Exception, ex:
        raise Exception(getMessage('ERR_EXTENDED_LOG_CONFIG_UPDATE') % (str(ex.toString())))

#############################
# Entry point to the script #
#############################


if len(sys.argv) < 3:
    usage()

i = 1

domain=''

while i < len(sys.argv):

    if sys.argv[i] == '-domain':
        domain = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-user':
        username = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminhost':
        host = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-adminport':
        port = sys.argv[i + 1]
        i += 2
    else:
        print  getMessage('ERR_USAGE') % (str(i),str(sys.argv[i]))
        usage()
        sys.exit(1)


SOA_DOMAIN=1
OSB_DOMAIN=2
SOA_OSB_DOMAIN=3


print ""
print ""
print ""
# passwd = "".join(java.lang.System.console().readPassword("%s", [getMessage('INPUT_ADMIN_PASSWORD') % (username)]))
passwd = os.environ['WLS_ADMIN_PW']

url= str(host) + ':' + str(port)
connect(username, passwd, url);


print ""
print getMessage('REF_CONFIG_WLS_TUNING_CONFIRMATION') %(str(domain))

propertyFile = "./resources/refconfig.properties"

if os.path.exists(propertyFile):
    properties = loadPropsFile(propertyFile);
else:
    print ""
    print getMessage('PROPERTY_FILE_MISSING') %(str(propertyFile))
    sys.exit(1)


now = datetime.datetime.now()
currentTimeStamp = str(now.strftime("%Y-%m-%d-%H:%M"))

wlstOut = tempfile.mktemp(suffix="_wlst_"+currentTimeStamp+".txt")
redirect(wlstOut,"false")


clusterExists = isCluster()
domainTopology = getDomainType()


osbClusterName=''
soaClusterName=''
serverList = []


osbTargetServer=''
soaTargetServer=''
serverTarget=''

if clusterExists:
    clusterList = getAllClusterNames()
    if domainTopology == SOA_DOMAIN or domainTopology == SOA_OSB_DOMAIN:
        soaTargetServer = getSoaClusterName(clusterList)
    if domainTopology == OSB_DOMAIN or domainTopology == SOA_OSB_DOMAIN:
        osbTargetServer = getOsbClusterName(clusterList)
else:
    serverList = getServerNames()
    osbTargetServer = getNonClusterOSBDomainTarget(serverList)
    soaTargetServer =  getNonClusterSOADomainTarget(serverList)



f = open('refconfig_log_'+currentTimeStamp+'.txt', 'w')


# f.write('\n' + getMessage('REF_CONFIG_WLS_TUNING_CONFIRMATION') %(str(domain)) + '.')

try:

    # choice = raw_input(getMessage('WLST_SCRIPT_EXECUTION_CONFIRMATION'))
    # if choice != 'y':
    #     sys.exit(1)


    updateJTAProperties(domain, properties, f);
    updateExtendedLogSetting(properties,f);

    save()
    activate()

    #EM changes
    if domainTopology == SOA_DOMAIN or domainTopology == SOA_OSB_DOMAIN:
        updateSOAEDNPollTimeOut(properties, f,clusterExists, soaTargetServer);

    f.close()
    print ''
    print ''
    print getMessage('REF_CONFIG_WLS_TUNING_SUCCESS')

except java.lang.Exception, ex:
    print ex.toString()
    cancelEdit('y')



print "\n"
print "\n"
print getMessage('WLST_SCRIPT_COMPLETION')
print ""

disconnect();
exit();

