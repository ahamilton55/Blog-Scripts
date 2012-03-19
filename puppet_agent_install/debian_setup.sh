#!/usr/bin/env bash

FULL_HOSTNAME="myhost.mydomain"
SHORT_HOST=`echo ${FULL_HOSTNAME} | cut -d'.' -f1`
APTITUDE=`which aptitude`
APT_KEY=`which apt-key`

###########
# Ping outside so that the router finds this instance * Should be fixed soon!*
###########
ping -c 4 8.8.8.8

###########
# Setup the hostname for the system. Puppet really relies on 
# the hostname so this must be done.
###########
hostname ${FULL_HOSTNAME}

sed -i -e "s/\(localhost.localdomain\)/${SHORT_HOST} ${FULL_HOSTNAME} \1/" /etc/hosts

###########
# Need to add in the aptitude workarounds for instances.
# * First disable dialog boxes for dpkg
# * Add the PPA for ec2-consistent-snapshot or else the update will hang.
###########
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

${APT_KEY} adv --keyserver keyserver.ubuntu.com --recv-keys BE09C571

###########
# Update the instance and install the puppet agent
###########
${APTITUDE} update
${APTITUDE} -y safe-upgrade
${APTITUDE} -y install puppet

PUPPET=`which puppet`

##########
# Setup the puppet manifest in /root/my_manifest
##########
cat >>/root/my_manifest.pp <<EOF
package {
    'apache2': ensure => installed
}

service {
    'apache2':
        ensure => true,
        enable => true,
        require => Package['apache2']
}

package {
    'vim': ensure => installed
}
EOF

############
# Apply the puppet manifest
############
$PUPPET apply /root/my_manifest.pp

############
# End of script cleanup.
############
export DEBIAN_FRONTEND=dialog
export DEBIAN_PRIORITY=high
