#!/bin/csh

pkg install --yes py36-ansible python36 git

git clone https://github.com/cohoe/shawshank /root/shawshank

cd /root/shawshank

ansible-playbook-3.6 -l localhost playbooks/setup.yaml
