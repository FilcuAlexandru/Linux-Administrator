# Apply SOA settings in WLST online mode. 

import os
import sys
import time as systime
import socket as sck

def msg(message):
    tstamp = systime.strftime("%Y-%m-%dT%H:%M:%S", systime.localtime())
    host = sck.gethostname()
    scriptname = os.path.basename(sys.argv[0])
    print("[%s] [%s] [%s] [%s]" % (tstamp, host, scriptname, message))

print str(sys.argv[0]) + " called with the following sys.argv array:"
for index, arg in enumerate(sys.argv):
    print "sys.argv[" + str(index) + "] = " + str(sys.argv[index])

if len(sys.argv) !=  7:
    msg("Invalid number of arguments")
    sys.exit(1)

adminUrl = None
soaClusterName = None
sharedStoragePath = None

i = 1
while i < len(sys.argv):
    if sys.argv[i] == '-adminUrl':
        adminUrl = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-soaCluster':
        soaClusterName = sys.argv[i + 1]
        i += 2
    elif sys.argv[i] == '-sharedStoragePath':
        sharedStoragePath = sys.argv[i + 1]
        i += 2
    else:
        msg('Unexpected argument switch at position ' + str(i) + ': ' + str(sys.argv[i]))
        sys.exit(1)

wlsAdminUser=os.environ['WLS_ADMIN_USER']
wlsAdminPw=os.environ['WLS_ADMIN_PW']

connect(wlsAdminUser, wlsAdminPw , adminUrl)
edit()
startEdit()
domain = cmo
soaCluster = getMBean("/Clusters/" + soaClusterName)
if soaCluster == None:
    raise ValueError("Cluster " + soaClusterName + "not found")

# Cluster
msg("Setting cluster migration basis to database ...")
soaCluster.setMigrationBasis("database")
soaCluster.setDataSourceForAutomaticMigration(getMBean('/JDBCSystemResources/WLSSchemaDataSource'))
save()
activate()
startEdit()

soaServers = list()
for server in domain.getServers():
    if server.getCluster() == soaCluster:
        soaServers.append(server)

soaMigratableTargets = list()
for mt in domain.getMigratableTargets():
    if mt.getCluster() == soaCluster:
        soaMigratableTargets.append(mt)


msg("Configure Service Migration for JTA  ...")
for server in soaServers:
    jtamt = getMBean("/Servers/" + server.getName() + "/JTAMigratableTarget/" +  server.getName())
    jtamt.setMigrationPolicy("failure-recovery")

msg("Activating admin server plain listen port ...")
cd ("/Servers/" + domain.getAdminServerName())
set("ListenPortEnabled", "true")

activate()
disconnect()
