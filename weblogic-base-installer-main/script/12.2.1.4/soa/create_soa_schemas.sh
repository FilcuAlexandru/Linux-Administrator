#!/bin/bash
#
# Install SOA binaries
# Created: 2020-09-11 dkovacs of virtual7

cd "$(dirname $0)/../../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

# Create response file
cat >$workdir/temp/soa_rcu_response <<EOF
#RCU Operation - createRepository, generateScript, dataLoad, dropRepository
operation=createRepository

#Enter the database connection details in the supported format. Database Connect String. This can be specified in the following format - For Oracle Database: host:port:SID OR host:port/service , For SQLServer, IBM DB2, MySQL and JavaDB Database: Server name/host:port:databaseName. For RAC database, specify VIP name or one of the Node name as Host name.For SCAN enabled RAC database, specify SCAN host as Host name.
connectString=$SOA_DB_CONNECT_STRING

#Database Type - [ORACLE|SQLSERVER|IBMDB2|EBR|MYSQL] - default is ORACLE
databaseType=ORACLE

#Database User
dbUser=$SOA_DBA_USER

#Database Role - sysdba or Normal
dbRole=SYSDBA

#This is applicable only for database type - EBR
#edition=

#Prefix to be used for the schema. This is optional for non-prefixable components.
schemaPrefix=$SOA_SCHEMA_PREFIX

#List of components separated by comma. Remove the components which are not needed.
componentList=STB,OPSS,SOAINFRA,UCSUMS,IAU,IAU_APPEND,IAU_VIEWER,MDS,WLS

#Specify whether dependent components of the given componentList have to be selected. true | false - default is false
#selectDependentsForComponents=false

#If below property is set to true, then all the schemas specified will be set to the same password.
useSamePasswordForAllSchemaUsers=true

#This allows user to skip cleanup on failure. yes | no. Default is no.
#skipCleanupOnFailure=no

#This allows user to skip dropping of table spaces during cleanup on failure. yes | no. Default is no.
#skipTableSpaceDropOnFailure=no

#Yes | No - default is Yes. This is applicable only for database type - SQLSERVER.
#unicodeSupport=no

#Location of ComponentInfo xml file - optional.
#compInfoXMLLocation=

#Location of Storage xml file - optional
#storageXMLLocation=

#Absolute path of Wallet directory. If wallet is not provided, passwords will be prompted.
#walletDir=

#true | false - default is false. RCU will create encrypted tablespace if TDE is enabled in the database.
#encryptTablespace=false

#true | false - default is false. RCU will create datafiles using Oracle-Managed Files (OMF) naming format if value set to true.
#honorOMF=false

#Tablespace properties for the component, STB. Enable the property only if the tablespace properties need to be overridden.
#STB.tablespaceProperties=$SOA_SCHEMA_PREFIX_STB

#Temporary tablespace properties for the component, STB. Enable the property only if the temp tablespace properties need to be overridden.
#STB.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, OPSS. Enable the property only if the tablespace properties need to be overridden.
#OPSS.tablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_OPSS

#Temporary tablespace properties for the component, OPSS. Enable the property only if the temp tablespace properties need to be overridden.
#OPSS.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, SOAINFRA. Enable the property only if the tablespace properties need to be overridden.
#SOAINFRA.tablespaceProperties=$SOA_SCHEMA_PREFIX_SOAINFRA

#Temporary tablespace properties for the component, SOAINFRA. Enable the property only if the temp tablespace properties need to be overridden.
#SOAINFRA.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, UCSUMS. Enable the property only if the tablespace properties need to be overridden.
#UCSUMS.tablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_UMS

#Temporary tablespace properties for the component, UCSUMS. Enable the property only if the temp tablespace properties need to be overridden.
#UCSUMS.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, IAU. Enable the property only if the tablespace properties need to be overridden.
#IAU.tablespaceProperties=$SOA_SCHEMA_PREFIX_IAU

#Temporary tablespace properties for the component, IAU. Enable the property only if the temp tablespace properties need to be overridden.
#IAU.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, IAU_APPEND. Enable the property only if the tablespace properties need to be overridden.
#IAU_APPEND.tablespaceProperties=$SOA_SCHEMA_PREFIX_IAU

#Temporary tablespace properties for the component, IAU_APPEND. Enable the property only if the temp tablespace properties need to be overridden.
#IAU_APPEND.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, IAU_VIEWER. Enable the property only if the tablespace properties need to be overridden.
#IAU_VIEWER.tablespaceProperties=$SOA_SCHEMA_PREFIX_IAU

#Temporary tablespace properties for the component, IAU_VIEWER. Enable the property only if the temp tablespace properties need to be overridden.
#IAU_VIEWER.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, MDS. Enable the property only if the tablespace properties need to be overridden.
#MDS.tablespaceProperties=$SOA_SCHEMA_PREFIX_MDS

#Temporary tablespace properties for the component, MDS. Enable the property only if the temp tablespace properties need to be overridden.
#MDS.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Tablespace properties for the component, WLS. Enable the property only if the tablespace properties need to be overridden.
#WLS.tablespaceProperties=$SOA_SCHEMA_PREFIX_WLS

#Temporary tablespace properties for the component, WLS. Enable the property only if the temp tablespace properties need to be overridden.
#WLS.tempTablespaceProperties=$SOA_SCHEMA_PREFIX_IAS_TEMP

#Variable required for component SOAINFRA. Database Profile
SOA_PROFILE_TYPE=$SOA_DB_PROFILE_TYPE

#Variable required for component SOAINFRA. Healthcare Integration
HEALTHCARE_INTEGRATION=NO
EOF

# Drop existing repository
msg "Dropping existing SOA schemas with prefix $SOA_SCHEMA_PREFIX ..."
export JAVA_HOME
cd $ORACLE_HOME/oracle_common/bin
./rcu -silent -dropRepository -connectString $SOA_DB_CONNECT_STRING \
  -dbUser $SOA_DBA_USER -dbRole SYSDBA -schemaPrefix $SOA_SCHEMA_PREFIX \
  -component STB -component OPSS -component SOAINFRA -component UCSUMS \
  -component IAU -component IAU_APPEND -component IAU_VIEWER -component MDS \
  -component WLS <<EOF
$SOA_DBA_PW
EOF

# Create repository
msg "Creating SOA schemas with prefix $SOA_SCHEMA_PREFIX ..."
./rcu -silent -responseFile $workdir/temp/soa_rcu_response <<EOF
$SOA_DBA_PW
$SOA_SCHEMA_PW
EOF
