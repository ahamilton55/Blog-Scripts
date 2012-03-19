#!/usr/bin/env bash

FULL_HOSTNAME="myhost.mydomain"
SHORT_HOST=`echo ${FULL_HOSTNAME} | cut -d'.' -f1`
YUM=`which yum`
RPM=`which rpm`
EPEL_PACKAGE="epel-release-5-4.noarch.rpm"
EPEL_URL="http://dl.fedoraproject.org/pub/epel/5/i386/"

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

echo -n ${FULL_HOSTNAME} >> /etc/sysconfig/network

###########
# Download and install EPEL repo which contains the puppet agent.
###########
curl -o /root/${EPEL_PACKAGE} ${EPEL_URL}/${EPEL_PACKAGE}

${RPM} -Uhv /root/${EPEL_PACKAGE}

###########
# Update the instance and install the puppet agent
###########
${YUM} -y update
${YUM} -y install puppet

PUPPET=`which puppet`

##########
# Setup the puppet manifest in /root/my_manifest
##########
cat >>/root/my_manifest.pp <<EOF
package {
    'httpd': ensure => installed
}

service {
    'httpd':
        ensure => true,
        enable => true,
        require => Package['httpd']
}

package {
    'vim-enhanced': ensure => installed
}
EOF

############
# Apply the puppet manifest
############
$PUPPET apply /root/my_manifest.pp

