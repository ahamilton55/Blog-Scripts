#!/usr/bin/env bash

hostname chef.mydomain.int
echo "HOSTNAME=chef.mydomain.int" >> /etc/sysconfig/network

yum -y update

#######
# Setup the required repos. EPEL, Aegisco, and rbel.
#######
curl -o /etc/yum.repos.d/aegisco.repo http://rpm.aegisco.com/aegisco/el5/aegisco.repo

rpm -Uhv http://rbel.frameos.org/rbel5

curl -o epel-release-5-4.noarch.rpm http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
rpm -Uhv epel-release-5-4.noarch.rpm 

########
# Install ruby and required tools for building the system
########
yum install -y ruby-1.8.7.352 ruby-libs-1.8.7.352 ruby-devel.x86_64 ruby-ri ruby-rdoc ruby-shadow gcc gcc-c++ automake autoconf make curl dmidecode

########
# Setup RubyGems
########
curl -o /tmp/rubygems-1.8.10.tgz http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz 
tar xzvf /tmp/rubygems-1.8.10.tgz 
ruby rubygems-1.8.10/setup.rb --no-format-executable

########
# Setup the chef ruby gem
########
gem install chef --no-ri --no-rdoc

########
# Setup the basic configuration files needed
########
cat >>/root/solo.rb <<EOF
file_cache_path "/var/chef-solo"
cookbook_path [ "/var/chef-solo/cookbooks" ]
EOF

cat >>/root/node.json <<EOF
{
    "run_list": [ "recipe[apache2]" ]
}
EOF

########
# Setup up cookbooks directory for chef solo
########
mkdir -p /var/chef-solo/cookbooks

########
# Download and untar the cookbooks provided by OpsCode on GitHub
########
curl -o /root/cookbooks.tgz https://nodeload.github.com/opscode/cookbooks/tarball/master
tar xzvf /root/cookbooks.tgz -C /root

########
# Add the apache2 cookbook to the chef solo cookbooks directory
########
cp -R /root/opscode-cookbooks-*/apache2 /var/chef-solo/cookbooks

########
# Run the node.rb JSON file to install apache2
########
chef-solo -c /root/solo.rb -j /root/node.json 
