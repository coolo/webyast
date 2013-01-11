#--
# Webyast framework
#
# Copyright (C) 2009, 2010 Novell, Inc. 
#   This library is free software; you can redistribute it and/or modify
# it only under the terms of version 2.1 of the GNU Lesser General Public
# License as published by the Free Software Foundation. 
#
#   This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more 
# details. 
#
#   You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software 
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
#++


  def stubs_functions
  
    
    
    #@ifcs = Interface.find :all
    interfaces = { }
    interfaces["eth0"] = Interface.new({"id" => "eth0", "bootproto" => "static", "ipaddr" => "192.168.178.1"})
    interfaces["eth1"] = Interface.new({"id" => "eth1", "ipaddr" => nil })

#    interfaces["eth1"] = Interface.new({"id" => "eth1", "bootproto" => "dhcp", "ipaddr" => nil})
    Interface.stubs(:find).with(:all).returns(interfaces)

    #ifc = Interface.find(id)
    eth0 = Interface.new({"id" => "eth0", "bootproto" => "static", "vendor" => "vendor", "ipaddr" => "10.10.4.187/16"})
    eth1 = Interface.new({"id" => "eth1", "ipaddr" => nil, "vendor" => "vendor"})
    
    # network = Network.find
    route = Route.new({"via"=>"192.168.178.1"}, "default")
    dns = Dns.new("nameservers"=>["192.168.178.1"], "searches"=>["example.com"])
    hostname = Hostname.new("dhcp_hostname"=>"1", "name"=>"test", "domain"=>"example.com")

    network = {
         "routes"=> route, 
         "dns"=> dns,
         "hostname"=> hostname,      
         "interfaces"=> { "eth0" => eth0, "eth1" => eth1}
    }

    Network.stubs(:find).returns(network)
    
    
    Interface.stubs(:find).with("eth0").returns(eth0)
    Interface.stubs(:find).with("eth1").returns(eth1)
    Interface.any_instance.stubs(:save).returns(true)
    
    #hostname = Hostname.find 
    hostname = Hostname.new({"dhcp_hostname" => "1", "domain" => "suse.de", "name" => "testhost"})
    Hostname.stubs(:find).returns(hostname)
    Hostname.any_instance.stubs(:save).returns(true)
    
    # stub dns = Dns.find 
    dns = Dns.new({"nameservers" => ["10.10.0.1", "10.10.2.88"], "searches" => ["suse.de", "novell.com"]})
    Dns.stubs(:find).returns(dns)
    Dns.any_instance.stubs(:save).returns(true)
    
    # stub route = Route.find "default" || route = Route.find :all
    route = Route.new({"via" => "10.10.0.8","id" => "default"})

    Route.stubs(:find).with("default").returns(route)
    Route.stubs(:find).with(:all).returns([route])
    Route.any_instance.stubs(:save).returns(true)

   # do not execute any commands via Open3 during tests
   Open3.stubs(:popen3).returns(["", "", 0])

  end
