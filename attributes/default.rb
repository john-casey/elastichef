#
# Cookbook Name:: elastichef
# Attribures:: default
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

# define our applications and environments
default['applications'] = ['elastichef']
default['environments'] = ['dev']

# define our dev app servers for our primary application
application = default['applications'][0]
environment = default['environments'][0]
role = 'app'
key_name = "#{application}-#{environment}-key"
default[application][environment]['key']['name'] = key_name
default[application][environment]['key']['path'] = ENV['HOME'] + '/.chef/keys'
default[application][environment]['server'][role]['count'] = 2
default[application][environment]['server'][role]['name_prefix'] = "#{application}-#{role}-#{environment}-"
default[application][environment]['server'][role]['options'] = {
  :availability_zone => 'us-east-1a',
  :bootstrap_options => {
    :block_device_mappings => [{
      :device_name => "/dev/sda2",
      :ebs => {
        :volume_size => 8, # 8 GiB
        :delete_on_termination => true
      }
    }],
    :image_id => 'ami-bc8131d4',
    :instance_type => 'm3.2xlarge',
    :key_name => key_name,
    :security_groups => ["#{application}-#{role}-sg"]
  },
  :driver => 'aws',
  :key_name => key_name,
  :monitoring_enabled => false,
  :ssh_username => 'root'
}

# define our dev db servers for our primary application
application = default['applications'][0]
environment = default['environments'][0]
role = 'db'
key_name = "#{application}-#{environment}-key"
default[application][environment]['key']['name'] = key_name
default[application][environment]['key']['path'] = ENV['HOME'] + '/.chef/keys'
default[application][environment]['server'][role]['count'] = 1
default[application][environment]['server'][role]['name_prefix'] = "#{application}-#{role}-#{environment}-"
default[application][environment]['server'][role]['options'] = {
  :availability_zone => 'us-east-1a',
  :bootstrap_options => {
    :block_device_mappings => [{
      :device_name => "/dev/sda2",
      :ebs => {
        :volume_size => 16, # 16 GiB
        :delete_on_termination => true
      }
    }],
    :image_id => 'ami-bc8131d4',
    :instance_type => 'm3.medium',
    :key_name => key_name,
    :security_groups => ["#{application}-#{role}-sg"]
  },
  :driver => 'aws',
  :key_name => key_name,
  :monitoring_enabled => false,
  :ssh_username => 'root'
}

