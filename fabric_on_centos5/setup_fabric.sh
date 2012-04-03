#!/usr/bin/env bash

if [ -n `which curl` ]; then
    curl -o /root/epel-release-5-4.noarch.rpm http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
elif [ -n `which wget` ]; then
    wget -O /root/epel-release-5-4.noarch.rpm http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
else
    echo "Please install either curl or wget. Exiting!"
    exit
fi

rpm -Uhv /root/epel-release-5-4.noarch.rpm

yum install -y python26 python26-devel gcc python-setuptools

cp -R /usr/lib/python2.4/site-packages/setuptools* /usr/lib/python2.6/site-packages/
cp -R /usr/lib/python2.4/site-packages/pkg_resources.py* /usr/lib/python2.6/site-packages/

if [ -n `which curl` ]; then
    curl -o /root/fabric.tgz https://nodeload.github.com/fabric/fabric/tarball/master
elif [ -n `which wget` ]; then
    wget -O /root/fabric.tgz https://nodeload.github.com/fabric/fabric/tarball/master
else
    echo "Please install either curl or wget. Exiting!"
    exit
fi

tar xzvf /root/fabric.tgz

FAB_DIR=`ls /root | grep fabric-fabric`

cd /root/${FAB_DIR}

python26 setup.py install

sed -i 's#/usr/bin/python26#/usr/bin/python26 -W ignore::DeprecationWarning#' /usr/bin/fab

cd /root

cat >fabfile.py <<EOF
from fabric.api import local

def release():
    local("cat /etc/redhat-release")
EOF

fab -H localhost release
