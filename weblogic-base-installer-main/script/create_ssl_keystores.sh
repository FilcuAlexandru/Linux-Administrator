#!/bin/bash
#
# Create keystores with self-signed certificates for WebLogic
# Created: 2016-10-11 dkovacs of virtual7

cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Creating keystores at $ID_STORE and $TRUST_STORE ..."
mkdir -p "$(dirname $ID_STORE)" "$(dirname $TRUST_STORE)"
rm -f "$ID_STORE" "$TRUST_STORE"

# generate certificates for each unique listen address
for cn in $(echo "${LISTENADDRESS[@]}" "${NM_LISTENADDRESS[@]}"|tr ' ' '\n'|sort|uniq); do 
  $JAVA_HOME/bin/keytool -genkeypair -alias "$cn" -keyalg RSA -keysize 2048 -dname "CN=$cn" -ext "san=dns:$cn" -validity 5479 -keystore "$ID_STORE" -storepass "$KEYSTOREPASS" -keypass "$KEYSTOREPASS" &&
    $JAVA_HOME/bin/keytool -exportcert -alias "$cn" -file "$workdir/temp/${cn}.crt" -keystore "$ID_STORE" -storepass "$KEYSTOREPASS" &&
    $JAVA_HOME/bin/keytool -importcert -alias "$cn" -file "$workdir/temp/${cn}.crt" -keystore "$TRUST_STORE" -storepass "$TRUSTSTOREPASS" -noprompt
    $JAVA_HOME/bin/keytool -certreq -alias "$cn" -file "$(dirname "$ID_STORE")/${cn}.csr" -keystore "$ID_STORE" -storepass "$KEYSTOREPASS" -keypass "$KEYSTOREPASS" ||
    exit 1
  msg "Added certificate for $cn to the keystores. CSR is has been written to $(dirname "$ID_STORE")/${cn}.csr"
done
chmod 600 $ID_STORE $TRUST_STORE

# Add root CA certificate to the trust store
# see - https://www.pki.bayern.de/vpki/allg/cazert/index.html
cat >/tmp/bayern-root-ca-2019.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIFqjCCA5KgAwIBAgIDBgAKMA0GCSqGSIb3DQEBCwUAMEYxCzAJBgNVBAYTAkRF
MRkwFwYDVQQKDBBGcmVpc3RhYXQgQmF5ZXJuMRwwGgYDVQQDDBNCYXllcm4tUm9v
dC1DQS0yMDE5MB4XDTE5MDIyODEyMTk1MFoXDTM0MDIyODA4MjAwOVowRjELMAkG
A1UEBhMCREUxGTAXBgNVBAoMEEZyZWlzdGFhdCBCYXllcm4xHDAaBgNVBAMME0Jh
eWVybi1Sb290LUNBLTIwMTkwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
AQCgZE62oedtTkPzAIxDr/mFOYBT83f2W3Ll+NszppNG+l4BxEjiPKu5lyEq0I8w
7SJUr8+RmYp1T+b0XeRd3xKEECOUkhSbwyQh0lHLc1pQj20syaEJ7+e74QL+UFCp
ZdU1FfjAclcWe4W3+NkYkU0BUtI1tRwZfQJyIugtiJPjK5nwQsHsuD1AkUqX4acE
YyclfWEXgJxBBZPxSRZaLNCcAX2VCruUnhfAhSd3s73icMVmnVLEucXeiHv9DeXf
vf6xrJrKJnV/RTSBr1C9O3xKxF9xRlY5CR8UKwsC0A2LNCu/P0bzhTk2E/Qp7hqN
/KPL8pEM7Vii8qyOCRRLNIgD0mZuAzdWig1V7ov1Y92zbFe7n0a7nFqlLqcCNv13
1RP9H7iH1SiCXdNfO+ACxHGbXwCczlwqCdZ89BIKFs6TW0FkCqrP6GVbeCfiXKFx
Ih9dM3jjZSyeljRY41z8EZ/YCa6UP5PubiowV6YwYcMVZCRfLHmpF9fh85MQRgde
irBmFxJd8LpXOfA/NSP0UIuoJFqygSiX/WBE26BOyA3xE0upw/4pZZf8rhsmASWP
F5z/PtqQvQamxfLB4hWIngGxOR5pY+GSDT50R+5posxQ7byxS5FbvLHAsiuaQUbU
OieRAL8sHM6VYIu+BjgBtaKafythFc/V/z/YMz7HJ0oMmQIDAQABo4GgMIGdMBIG
A1UdEwEB/wQIMAYBAf8CAQIwEQYDVR0OBAoECEQezjUjfkDbMGQGA1UdIARdMFsw
WQYLKwYBBAGBlkIBAgQwSjBIBggrBgEFBQcCARY8aHR0cHM6Ly93d3cucGtpLmJh
eWVybi5kZS9tYW0vcGtpL3Zwa2kvcG9saWN5X2JheWVybi1wa2kucGRmMA4GA1Ud
DwEB/wQEAwIBBjANBgkqhkiG9w0BAQsFAAOCAgEAOoLDRYJa0Ur4y/4GFcxXVlVG
HYFRofxEfMLJJfnj+Wp61ESJM7eUmjAXnlL+pbtz/wiRXWFDglyWUjGqkClX8H33
ijTrOc243Lv/wSbPz/SgS3tW8p9AK/M6RhhOfx6O/CdtjltOaQH6U840eEH3Q5uh
K2Dco0ZEUGw+OJ/Kia6gSMycH8odNzDKrlqc+PCXZjXeCQwO7H7MdK5YPYGZAeQf
uEnypGZIa/2YLuAW6rLHKhbTumKUJnZMovpstGGzZBXO7Puw4o9hxhHvw4bRh1aH
EsWtAYtK6PThxY8DxeqaTdGi86Bl784lPsn9yruZcQYxYmlAWwSs6S6uRiOuhdpQ
EXU3it28g2oupkD3yGZ29Zhu2R0LwQK0TRu0xxhyqkuxmkDLFNnVqv968QpIKOej
8ivdKmgSIEcodSFyKl+WFlMIu0jwh358dHkxJ9vPogmuSWnp36OdxAGgNl0OH0Yd
FmY0AW7eA2/Xt6jsTDhM8j8gvBnt421GIwQeoka2O8G51SXZPUQbd/qf1mus4N8a
t0SIDfz+w+ExbMeYeoFCG+DtcFChm96Z3W2ClQYHrDCO+g2JzWNFuCn60ZjJ74IF
ZOnjKRHU1/qR1LjDwExEIu/pSz+trinq2TiscuKjPn1lls+kg+/vP+ZOs+Dq/w/d
TfJR8Yg4DXh4zz18G4s=
-----END CERTIFICATE-----
EOF
$JAVA_HOME/bin/keytool -importcert -alias "bayern-root-ca-2019" -file "/tmp/bayern-root-ca-2019.pem" -keystore "$TRUST_STORE" -storepass "$TRUSTSTOREPASS" -noprompt &&
  rm /tmp/bayern-root-ca-2019.pem
