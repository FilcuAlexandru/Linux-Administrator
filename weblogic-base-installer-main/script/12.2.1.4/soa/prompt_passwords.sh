# Ask for passwords if not already set in the environment
if [ "$SOA_DBA_PW" ]; then
  msg "Password for database user $SOA_DBA_USER has been set from envvar SOA_DBA_PW"
else
  echo "Envvar SOA_DBA_PW is not set. Password for database user $SOA_DBA_USER (the user must alreasdy exist)"
  readpasswd
  export SOA_DBA_PW="$pass"
fi

if [ "$SOA_SCHEMA_PW" ]; then
  msg "Password for all SOA schema users has been set from envvar SOA_SCHEMA_PW"
else
  echo "Envvar SOA_SCHEMA_PW is not set. Password for all SOA schema users"
  readpasswd
  export SOA_SCHEMA_PW="$pass"
fi