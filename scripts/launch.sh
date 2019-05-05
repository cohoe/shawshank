#!/bin/csh

# Make sure we're running as root
set uidnumber = `id -u`
if ("$uidnumber" != "0") then
    echo "You must run this as the root user."
    exit
endif

# Install required packages
/usr/sbin/pkg install -y git py36-ansible python3

# Clone the repo
set repodir = "/root/shawshank"
if (-d $repodir) then
    cd $repodir
    git pull
else
    git clone https://github.com/cohoe/shawshank $repodir
endif

echo "SUCCESS: You're all set!"
echo ""
echo "The repo is at $repodir. An example run would be:"
echo "  ansible-playbook-3.6 -l localhost playbooks/setup.yaml"
echo ""

# Run the setup playbook
cd $repodir
ansible-playbook-3.6 -l localhost playbooks/setup.yaml
