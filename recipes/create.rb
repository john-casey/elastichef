#
# Cookbook Name:: elastichef
# Recipe:: default
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

# Set up our keys
environments.each do |environment|
  applications.each do |application|
    key_path = node[application][environment]['key']['path']
    #directory key_path do
    #  recursive true
    #end
    key_name = node[application][environment]['key']['name']
    private_key "#{key_name}.pem" do
      format :pem
      type :rsa
    end
    aws_key_pair key_name do 
      allow_overwrite false
      private_key_path "#{key_name}.pem"
    end
  end
end

# Set up our security groups using the following naming convention
# Format: "#{application[0]}-#{role}-sg"
application = applications[0]
aws_security_group "#{application}-app-sg" do
  description "#{application} app servers" 
  inbound_rules [
    {:ports =>   22, :protocol => :tcp, :sources => ['0.0.0.0/0'] },
    {:ports =>   80, :protocol => :tcp, :sources => ['0.0.0.0/0'] }
  ]
end
aws_security_group "#{application}-db-sg"  do
  description "#{application} db servers" 
  inbound_rules [
    {:ports =>   22, :protocol => :tcp, :sources => ['0.0.0.0/0'] },
    {:ports => 5432, :protocol => :tcp, :sources => ['0.0.0.0/0'] }
  ]
end

# Create our machines
with_machine_options({
  :key_name => 'elastichef-dev-key'
})
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
          machine server_name do
            # ***FIXME*** Add generic role names here
            machine_options server_options
          end
        end
      end
    end
  end
end

