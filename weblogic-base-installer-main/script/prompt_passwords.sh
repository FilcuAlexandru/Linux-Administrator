# Ask for passwords if not already set in the environment
if [ "$WLS_ADMIN_PW" ]; then
  msg "Password for user weblogic has been set from envvar WLS_ADMIN_PW"
else
  echo "Envvar WLS_ADMIN_PW is not set. Password for WLS user weblogic"
  readpasswd
  export WLS_ADMIN_PW="$pass"
fi
if [ "$WLS_OPERATOR_PW" ]; then
  msg "Password for user operator has been set from envvar WLS_OPERATOR_PW"
else
  echo "Envvar WLS_OPERATOR_PW is not set. Password for WLS user operator"
  readpasswd
  export WLS_OPERATOR_PW="$pass"
fi
if [ "$KEYSTOREPASS" ]; then
  msg "Password for identity keystore has been set from envvar KEYSTOREPASS"
else
  echo "Envvar KEYSTOREPASS is not set. Password for SSL identity keystore and keys"
  readpasswd
  export KEYSTOREPASS="$pass"
fi
if [ "$TRUSTSTOREPASS" ]; then
  msg "Password for trust keystore has been set from envvar TRUSTSTOREPASS"
else
  echo "Envvar TRUSTSTOREPASS is not set. Password for SSL trust keystore"
  readpasswd
  export TRUSTSTOREPASS="$pass"
fi
