#####################################
# Cadence for WebLogic Installation #
#####################################
msg "WebLogic Base Installer $wls_installer_version for WebLogic $weblogic_version"

# Check prerequisites
for host in "${MACHINES[@]}"; do
  dostep script/pre_check.sh $host
  dostep script/${weblogic_version}/pre_check.sh $host
done

# Install binaries on each host
for host in "${MACHINES[@]}"; do
  dostep script/${weblogic_version}/install_jdk8.sh $host
  dostep script/${weblogic_version}/enable_java_unlimited_strength_crypto.sh $host
  if [ "$JAVA_USE_NONBLOCKING_PRNG" == "true" ]; then
    dostep script/${weblogic_version}/set_java_random_source.sh $host
  fi
  dostep script/${weblogic_version}/install_wls_binaries.sh $host
  dostep script/${weblogic_version}/install_wls_patches.sh $host
  dostep script/install_wdt.sh $host
done

msg "----- S A F E   R E S T A R T   P O I N T -------"

# Create Administration Server domain home
dostep script/create_base_domain.sh
dostep script/create_ssl_keystores.sh
dostep script/install_control_scripts.sh
dostep script/create_additional_directories.sh
dostep script/create_operator_user.sh
dostep script/configure_domain.sh

# Create Managed Server domain home on each host
dostep script/pack_domain.sh
for host in "${MACHINES[@]}"; do
  dostep script/unpack_domain.sh $host
  dostep script/configure_nodemanager.sh $host
done

# Deploy monitoring agent
dostep script/deploy_jolokia.sh

# Move config files and logs
for host in "${MACHINES[@]}"; do
  dostep script/relocate_logs.sh $host
done
if [ "$HA_DOMAIN" == "true" ] && [ "$SHAREDSTORAGE_PATH" ]; then
  for host in "${MACHINES[@]}"; do
    dostep script/relocate_to_shared_storage.sh $host
  done
fi

# Enable admin channel
if [ "$ADMIN_CHANNEL_ENABLED" == "true" ]; then
  dostep script/enable_admin_channel.sh
fi

# Create init.d scripts
for host in "${MACHINES[@]}"; do
  dostep script/create_init_script.sh $host
done

# Create readme and preferences files
for host in "${MACHINES[@]}"; do
  dostep script/create_readme.sh $host
done

# TODO: Start everything

# Show installation summary
dostep script/show_completed_message.sh

####### END CADENCE ######