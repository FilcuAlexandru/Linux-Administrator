#
# Fuction definitions and environent settings for SOA 12.2.1.4
#

soa_version="12.2.1.4"

# source parent level functions.sh
. $workdir/script/$weblogic_version/functions.sh

# Set defaults and derived parameters
SOA_SCHEMA_PREFIX=${SOA_SCHEMA_PREFIX^^}
SOA_DB_PROFILE_TYPE="LARGE"
ASERVER_START_TIMEOUT="600" # overwrites default from base functions.sh
ASERVER_MEMORY="-Xms4g -Xmx4g" # Administration server memory args

# Set script with the installation steps
CADENCE="$workdir/script/$weblogic_version/soa/cadence.sh" # overwrites default from base functions.sh
