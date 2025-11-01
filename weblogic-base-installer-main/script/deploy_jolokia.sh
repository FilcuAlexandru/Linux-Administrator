#!/bin/bash
#
# Prepare and deploy jolokia agent
# Created: 2019-03-14 dkovacs of virtual7

cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh


# Unpack jolokia.war
mkdir $workdir/temp/jolokia &&
  cd $workdir/temp/jolokia &&
  $JAVA_HOME/bin/jar -xf "$SOFTWARE_REPO_PATH/rolandhuss/jolokia.war" || exit 1


# Create jolokia-access.xml in jolokia.war
cat >WEB-INF/classes/jolokia-access.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>

<!--
  Sample definitions for restricting the access to the Jolokia agent. Adapt this
  file and copy it over to 'jolokia-access.xml', which get's evaluated during
  runtime (if included in the war).

  You can restrict the available methods in principale as well as the accessible
  attributes and operations in detail.
-->

<restrict>

  <!-- List of remote hosts which are allowed to access this agent. The name can be
       given as IP or FQDN. If any of the given hosts matches, access will be allowed
      (respecting further restrictions, though). If <remote> ... </remote> is given
      without any host no access is allowed at all (probably not what you want).

      You can also specify a subnetmask behind a numeric IP adress in which case any
      host within the specified subnet is allowed to access the agent. The netmask can
      be given either in CIDR format (e.g "/16") or as a full netmask (e.g. "/255.255.0.0")
  -->
  <remote>
    <host>localhost</host>
EOF

# Insert a <host> element for each unique listen-address and hostname
for la in $(echo "${LISTENADDRESS[@]}" "${NM_LISTENADDRESS[@]}" "${MACHINES[@]}"|tr ' ' '\n'|sort|uniq); do
cat >>WEB-INF/classes/jolokia-access.xml <<EOF
    <host>$la</host>
EOF
done

cat >>WEB-INF/classes/jolokia-access.xml <<EOF
  </remote>

  <!--
  List of allowed commands.

  If this sections is present, it influence the following section.

  For each command type present, the principle behaviour is allow this command for all
  MBeans. To remove an MBean (attribute/operation), a <deny> section has to be added.

  For each comman type missing, the command is disabled by default. For certain MBeans
  it can be selectively by enabled by using an <allow> section below

  Known types are:

  * read
  * write
  * exec
  * list
  * version
  * search

  A missing <commands> section implies that every operation type is allowed (and can
  be selectively controlled by a <deny> section)
  -->

  <commands>
    <command>read</command>
    <command>list</command>
    <command>version</command>
    <command>search</command>
  </commands>


  <!--
  Restrict access only via the specified methods

  Example which allows only POST requests:
  <http>
    <method>post</method>
  </http>
  -->

  <!--
  Cross origin protection (CORS).

  You can configure which cross origins are given allowance by the browser.
  With strict-checking, the Origin: header can be also be checked on the server side,
  which results in an error if it doesn't match any specified pattern.
  -->

  <!--
      Example which allows access from www.jolokia.org and the domain jmx4perl.org for CORS
      but does also server side check to prevent CSRF attacks:

  <cors>
      <allow-origin>http://www.jolokia.org</allow-origin>
      <allow-origin>*://*.jmx4perl.org</allow-origin>

      <strict-checking/>
  </cors>
  -->

  <!-- For each command type missing in a given <commands> section, for certain MBeans (which
       can be a pattern, too) an command be alloed. Note that an <allow> entry e.g. for reading
       an attribute of an certain MBean has no influence if reading is enabled globally anyway -->
  <allow>

    <!-- Allow for this MBean the attribute "HeapMemoryUsage" for reading and writing, the attribute
         "Verbose" for reading only and the operation "gc". "read", "write" and/or "exec" has to be omitted
          in the <commands> section above.

         Example: ->
    <mbean>
      <name>java.lang:type=Memory</name>
      <attribute>HeapMemoryUsage</attribute>
      <attribute mode="read">Verbose</attribute>
      <operation>gc</operation>
    </mbean>
    <mbean>
      <name>java.lang:type=Threading</name>
      <attribute>ThreadCount</attribute>
    </mbean>
    -->

    <!-- Allow access to the j4p configuration operations, which are needed for proper check_jmx4perl
         operation -->
    <mbean>
      <name>jolokia:type=Config</name>
      <operation>*</operation>
      <attribute>*</attribute>
    </mbean>
    <mbean>
      <name>java.lang:type=Threading</name>
      <operation>findDeadlockedThreads</operation>
    </mbean>
  </allow>

  <!-- MBean access can be restricted by a <deny> section for commands enabled in a <commands> section
       (or when the <commands> section is missing completely in which case all commands are allowed)
  -->
  <deny>
    <mbean>
      <!-- Exposes user/password of data source, so we forbid this one -->
      <name>com.mchange.v2.c3p0:type=PooledDataSource,*</name>
      <attribute>properties</attribute>
    </mbean>
  </deny>
</restrict>

<!--
  ~ Copyright 2009-2014 Roland Huss
  ~
  ~ Licensed under the Apache License, Version 2.0 (the "License");
  ~ you may not use this file except in compliance with the License.
  ~ You may obtain a copy of the License at
  ~
  ~ http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing, software
  ~ distributed under the License is distributed on an "AS IS" BASIS,
  ~ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  ~ See the License for the specific language governing permissions and
  ~ limitations under the License.
  -->

EOF

# zip to final jolokia-eployment.war
mkdir -p "$APPLICATION_HOME/jolokia" &&
  $JAVA_HOME/bin/jar -cf "$APPLICATION_HOME/jolokia/jolokia-deployment.war" META-INF WEB-INF || exit 1
msg "Created $APPLICATION_HOME/jolokia/jolokia-deployment.war"
cd $workdir

# Start the admin server
msg "Starting AdminServer ..."
$ASERVER_HOME/custom_scripts/command-control.sh start $ADMINSERVER_NAME

# Credentials will be passed as env. vars to wlst
export WLS_ADMIN_USER
export WLS_ADMIN_PW

# Deploy
cat >$workdir/temp/deploy_jolokia.py << EOF
$(cat $workdir/temp/python_common)

# Get parameters from the environment
wlsAdminUser=os.environ['WLS_ADMIN_USER']
wlsAdminPw=os.environ['WLS_ADMIN_PW']

url = DomainConfig().get_connect_url('$ADMINSERVER_NAME')
connect(wlsAdminUser, wlsAdminPw, url)

#edit()
#startEdit()

# Deploy jolokia.war to all servers
targets_all="$(echo ${SERVERS[@]}|tr ' ' ',')"
msg("Deploying jolokia. Targets: " + targets_all)
deploy('jolokia-deployment', '$APPLICATION_HOME/jolokia/jolokia-deployment.war', targets_all)
startApplication('jolokia-deployment')

#activate()
EOF

$ASERVER_HOME/custom_scripts/wlst.sh $workdir/temp/deploy_jolokia.py
rc=$?

# Stop the admin server
msg "Stopping the Administration Server ..."
$ASERVER_HOME/custom_scripts/command-control.sh stop $ADMINSERVER_NAME

exit $rc
