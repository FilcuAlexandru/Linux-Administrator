# Changelog
## WebLogic Base Installer
### 2.3
- Built-in support for SOA installation
- Removed support for extensions

### 2.2
- Support for SLES 15
- The ADMIN_FLIP_IF configuration parameter now requires an interface name (e.g. eth0) rather than an alias (e.g. eth0:0).
- The ADMIN_FLIP_IF_MASK configuration parameter has been removed. The floating IP netmask is now set automatically.
- JUL-2023 Critical Patch Update
- Changed JDK version to 8u381 for WLS 12c
- Changed JDK version to 11.0.20 for WLS 14c
- Changed WDT version to 3.2.5
- Certificates are created with SAN extension to comply with RFC 6125

### 2.1
- Fixed: command-control.sh gives correct return code on exit

### 2.0
- Support for WebLogic Server 14c (14.1.1.0) in addition to 12c (12.2.1.4)
- OCT-2022 Critical Patch Update
- Changed JDK version to 8u351 for WLS 12c
- Consistent date format in log files for 12c and 14c
- Separate domain and application directories on shared storage

### 1.9
- Changed JDK version to 8u341
- JUL-2022 Critical Patch Update for WebLogic Server
- Changed WDT version to 2.3.3

### 1.8
- SSL-only - plain listen ports are disabled
- SSL-only - default protocol is set to t3s in config.xml
- SSL-only - secure cluster replication is enabled
- Added WebLogic Deploy Tooling installation in BASEDIR/product/weblogic-deploy
- Added graceful shutdown option to command_control.sh and menu_control.sh

### 1.5
- JAN-2022 Critical Patch Update for WebLogic Server
- Changed JDK version to 8u321
- Extended access log format

### 1.4
- Changed JDK version to 8u291
- Keep oraInst.loc under BASEDIR/product
- APR-2021 Critical Patch Update for WebLogic Server
- fixed - getIPForName() to return ipv4 address only
- Removed dead code
- JAVA_USE_NONBLOCKING_PRNG is hardcoded to 'true' and can no longer be configured in install.conf
- Improved message text

### 1.2
- Fixed: JVM Parameter -Djavax.net.ssl.trustStore

### 1.1
- Fixed: jolokia not accessible when /etc/hosts has an entry for the hostname
- General cleanup and refactoring
- Changed JDK version to 8u241
- New feature: extension modules
- Added JVM parameter -Djavax.net.ssl.trustStore to managed servers

### 1.0
- install.sh optionally reads passwords from the environment to allow noninteractive usage
- install.sh no longer requires typing in "okay"
- install.sh returns the return value of the last executed step
- deploy_jolokia.sh changed to use jar instead of zip/unzip
- Root CA certificate Bayern-Root-CA-2019 is added to the WebLogic trust store
- Create CSRs for the generated certificates
- Added configuration parameter to switch to /dev/urandom instead of /dev/random as random number source

### 0.64
- Support for WebLogic 12.2.1.4
- ORACLE_HOME directory changed from "fmw" to "fmw_12.2.1.4"
- jvm-options.sh and addserver.sh obtain credentials from the environment
