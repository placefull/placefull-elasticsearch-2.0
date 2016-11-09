#
# Cookbook Name:: placefull-elasticsearch-2
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe "java"
include_recipe "placefull-nginx"



instance = search(:aws_opsworks_instance, "self:true").first
elasticsearch_user 'elasticsearch'
elasticsearch_install 'elasticsearch' do
type :package
end
elasticsearch_configure 'elasticsearch' do
allocated_memory '1g'
configuration ({
'cluster.name' => 'placefull-es-2',
'node.name' => "#{instance['hostname']}",
'node.master' => 'true',
'node.data' => 'true',
'bootstrap.mlockall' => 'false',
'network.host' => '_ec2:privateIp_',
'http.host' => '127.0.0.1',
'plugin.mandatory' => 'cloud-aws',
'discovery.type' => 'ec2',
'discovery.zen.minimum_master_nodes' => '2',
'discovery.zen.ping.multicast.enabled' => 'false',
'cloud.node.auto_attributes' => 'true',
'cloud.aws.region' => 'us-east-1',
'cluster.routing.allocation.awareness.attributes' => 'rack_id',
'node.rack_id' => 'us-east-1b'

})
end

elasticsearch_plugin 'cloud-aws' do
  action :install
end

elasticsearch_service 'elasticsearch' do
service_actions [:enable, :start]
end



elasticsearch_plugin 'head' do
url 'mobz/elasticsearch-head'
notifies :restart, 'elasticsearch_service[elasticsearch]', :delayed
end
