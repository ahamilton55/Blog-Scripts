#!/usr/bin/env bash

#######
# Install the Chef client and then install nginx using chef-solo.
#######
APT_KEY=`which apt-key`
APTITUDE=`which aptitude`
HOSTNAME=`which hostname`

SYSTEM_NAME="chef.mydomain.int"
SHORT_SYSTEM_NAME=`echo ${SYSTEM_NAME} | cut -d'.' -f1`

COOKBOOK_REPO="https://nodeload.github.com/opscode/cookbooks/tarball/master"
CHEF_DIR="/var/chef-solo/"
CHEF=""

DEFAULT_DIR="/root/"

#######
# Setup the hostname on the system
#######
${HOSTNAME} ${SYSTEM_NAME}
echo ${SYSTEM_NAME} > /etc/hostname
sed -i -e "s/\(localhost.localdomain\)/${SYSTEM_NAME} ${SHORT_SYSTEM_NAME} \1/" /etc/hosts

#######
# Make aptitude stop asking questions
#######
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

#######
# Make sure that lsb_release is installed
#######
if [ -z `which lsb_release` ]; then 
    ${APTITIDUE} -y install lsb-release
fi

#######
# Setup the OpsCode APT repo
#######
echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | tee /etc/apt/sources.list.d/opscode.list

${APT_KEY} adv --keyserver keyserver.ubuntu.com --recv-keys 83EF826A

#######
# Install the ec2-consistent shapshot PPA key for easier updating of ECC images
#######
${APT_KEY} adv --keyserver keyserver.ubuntu.com --recv-keys BE09C571

#######
# Update the system
#######
${APTITUDE} update
${APTITUDE} -y safe-upgrade

#######
# Install chef-solo
#######
${APTITUDE} -y install chef

CHEF=`which chef-solo`

#######
# Create the needed config files for chef-solo
#
# solo.rb   -- Basic configuration for chef-solo
# node.json -- Information we want to give to chef-solo about the what
#              to install.
########
cat >>${DEFAULT_DIR}/solo.rb <<EOF
file_cache_path "${CHEF_DIR}"
cookbook_path ["${CHEF_DIR}/cookbooks"]
EOF

cat >>${DEFAULT_DIR}/node.json <<EOF
{
    "run_list": [ "recipe[nginx]" ]
}
EOF

########
# Create the chef-solo cookbooks directory
########
mkdir -p ${CHEF_DIR}/cookbooks

########
# Download the OpsCode GitHub cookbook repo. Move the nginx cookbook to 
# the chef-solo cookbooks directory created above.
########
curl -o ${DEFAULT_DIR}/cookbooks.tgz ${COOKBOOK_REPO}
tar xzvf ${DEFAULT_DIR}/cookbooks.tgz -C ${DEFAULT_DIR}
cp -R ${DEFAULT_DIR}/opscode-cookbooks-*/nginx/ ${CHEF_DIR}/cookbooks/

########
# Run chef-solo to install the cookbooks refrenced in node.json above
########
${CHEF} -c ${DEFAULT_DIR}/solo.rb -j ${DEFAULT_DIR}/node.json 

########
# Create the basic directory structure for nginx and a basic index.html
########
mkdir -p /var/www/nginx-default

cat >>/var/www/nginx-default/index.html <<EOF
<html>
  <head><title>Testing nginx Installation</title></head>
  <body>
    <h1>My temporary site after installing nginx with Chef!</h1>
  </body>
</html>
EOF

############
# End of script cleanup.
############
export DEBIAN_FRONTEND=dialog
export DEBIAN_PRIORITY=high
