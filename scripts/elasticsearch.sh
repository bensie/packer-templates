#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

elasticsearch_version="1.3.2"

apt-get -y install openjdk-7-jre-headless
cd /tmp
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$elasticsearch_version.deb
dpkg -i elasticsearch-$elasticsearch_version.deb
rm elasticsearch-$elasticsearch_version.deb
