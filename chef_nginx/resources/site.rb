#
# Cookbook Name:: nginx
# Resource:: site
#
# Author:: AJ Christensen <aj@junglist.gen.nz>
# Author:: Tim Smith <tsmith@chef.io>
#
# Copyright 2008-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

provides :nginx_site

property :name, String, name_property: true
property :variables, Hash, default: {}
property :cookbook, String
property :template, String
property :enable, [String, true, false]

action :enable do
  # this is pretty evil, but gives us backwards compat with the old
  # definition where there was an enable property vs a true action
  if new_resource.enable
    Chef::Log.warn('The "enable" property in nginx_site is deprecated. Use "action :enable" instead.')
  elsif new_resource.enable == false || new_resource.enable == 'false'
    Chef::Log.warn('The "enable" property in nginx_site is deprecated. Use "action :disable" instead.')
    action_disable
    return # don't perform the actual enable action afterwards
  end

  # use declare_resource so we can have a property also named template
  declare_resource(:template, "#{node['nginx']['dir']}/sites-available/#{new_resource.name}") do
    source new_resource.template
    variables(new_resource.variables)
    notifies :reload, 'service[nginx]'
    only_if { new_resource.template }
  end

  execute "nxensite #{new_resource.name}" do
    command "#{node['nginx']['script_dir']}/nxensite #{new_resource.name}"
    notifies :reload, 'service[nginx]'
    not_if do
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{new_resource.name}") ||
        ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/000-#{new_resource.name}")
    end
  end
end

action :disable do
  execute "nxdissite #{new_resource.name}" do
    command "#{node['nginx']['script_dir']}/nxdissite #{new_resource.name}"
    notifies :reload, 'service[nginx]'
    only_if do
      ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/#{new_resource.name}") ||
        ::File.symlink?("#{node['nginx']['dir']}/sites-enabled/000-#{new_resource.name}")
    end
  end
end
