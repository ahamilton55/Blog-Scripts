#!/usr/bin/env bash

######
# Install Chef on CentOS 6. After the installation chef-solo will install
# vim. I'd like to install something better but apache2 and nginx cookbooks
# are currently broken.
######

YUM=`which yum`
RPM=`which rpm`
HOSTNAME=`which hostname`
RUBY=""
GEM=""

SYSTEM_NAME="chef.mydomain.int"

DEFAULT_DIR="/root/"
TMP_DIR="/tmp/"

CHEF_DIR="/var/chef-solo/"
CHEF=""

######
# Set the hostname of the instance
######
${HOSTNAME} ${SYSTEM_NAME}
if [ -z `grep "HOSTNAME" /etc/sysconfig/network` ]; then
    echo "HOSTNAME=${SYSTEM_NAME}" >> /etc/sysconfig/network
else
    sed -i -e "s/\(HOSTNAME=\).*/\1${SYSTEM_NAME}/" /etc/sysconfig/network
fi

######
# Update the instance
######
${YUM} -y update

#######
# Setup the required repos. EPEL, Aegisco, and rbel.
#######
${RPM} -Uhv http://rbel.frameos.org/rbel6

########
# Install ruby and required tools for building the system
########
${YUM} install -y ruby-1.8.7.352 ruby-libs-1.8.7.352 ruby-devel.x86_64 ruby-ri ruby-rdoc ruby-shadow gcc gcc-c++ automake autoconf make curl dmidecode

RUBY=`which ruby`
########
# Setup RubyGems
########
curl -o ${TMP_DIR}/rubygems-1.8.10.tgz http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz 
tar xzvf ${TMP_DIR}/rubygems-1.8.10.tgz -C ${TMP_DIR}
${RUBY} ${TMP_DIR}rubygems-1.8.10/setup.rb --no-format-executable

GEM=`which gem`
########
# Setup the chef ruby gem
########
${GEM} install chef --no-ri --no-rdoc

CHEF=`which chef-solo`

########
# Setup the basic configuration files needed
########
cat >>${DEFAULT_DIR}/solo.rb <<EOF
file_cache_path "${CHEF_DIR}"
cookbook_path [ "${CHEF_DIR}/cookbooks" ]
EOF

cat >>${DEFAULT_DIR}/node.json <<EOF
{
    "run_list": [ "recipe[vim]" ]
}
EOF

########
# Setup up cookbooks directory for chef solo
########
mkdir -p ${CHEF_DIR}/cookbooks

########
# Download and untar the cookbooks provided by OpsCode on GitHub
########
curl -o ${DEFAULT_DIR}/cookbooks.tgz https://nodeload.github.com/opscode/cookbooks/tarball/master
tar xzvf ${DEFAULT_DIR}/cookbooks.tgz -C ${DEFAULT_DIR}

########
# Add the apache2 cookbook to the chef solo cookbooks directory
########
cp -R ${DEFAULT_DIR}/opscode-cookbooks-*/vim ${CHEF_DIR}/cookbooks

########
# Run the node.rb JSON file to install apache2
########
chef-solo -c ${DEFAULT_DIR}/solo.rb -j ${DEFAULT_DIR}/node.json 
