#
# Cookbook Name:: elastichef
# Recipe:: destroy
#
# Copyright (C) 2015 Innovisors
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'chef/provisioning'
require 'chef/provisioning/aws_driver'

# Get our root attributes
environments = node['environments']
applications = node['applications']

# Destroy our machines
with_driver 'aws'
machine_batch 'Converge Servers' do
  applications.each do |application|
    environments.each do |environment|
      servers = node[application][environment]['server']
      servers.each do |role,server|
        server_count = server['count']
        1.upto(server_count) do |server_index|
          server_name_prefix = server['name_prefix']
          server_name = "#{server_name_prefix}#{server_index}"
          server_options = server['options']
          begin
            machine server_name do
              action :destroy
              machine_options server_options
            end
          rescue Exception => msg
              Chef::Log.warn "Unable to destroy #{server_name}. #{msg}"
          end
        end
      end
    end
  end
end

# Delete our security groups
security_group_set = Set.new
applications.each do |application|
  environments.each do |environment|
    servers = node[application][environment]['server']
    servers.each do |role,server|
      security_group = "#{application}-#{role}-sg"
      if !security_group_set.include? security_group
        security_group_set.add security_group
        begin
          aws_security_group security_group do
            action :delete
          end
        rescue Exception => msg
          Chef::Log.warn "Unable to delete AWS security group #{security_group}. #{msg}"
        end
      end
    end
  end
end

# Delete our keys
key_set = Set.new
applications.each do |application|
  environments.each do |environment|
    key_name = node[application][environment]['key']['name']
    if !key_set.include? key_name
      key_set.add key_name
      begin
        aws_key_pair key_name do 
          action :delete
        end
      rescue Exception => msg
        Chef::Log.warn "Unable to delete AWS key pair #{key_name}. #{msg}"
      end
      begin
        private_key "#{key_name}.pem" do
          action :delete
        end
      rescue Exception => msg
        Chef::Log.warn "Unable to delete private key #{key_name}.pem #{msg}"
      end
    end
  end
end
