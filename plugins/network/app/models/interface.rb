#--
# Copyright (c) 2009 Novell, Inc.
#
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#++
# = Network interface model
# Provides set and gets resources from YaPI network module.
# Main goal is handle YaPI specific calls and data formats. Provides cleaned
# and well defined data.

require 'base'
require 'ipaddr'
require "open3"

class Interface < BaseModel::Base

  IPADDR_REGEX = /([0-9]{1,3}.){3}[0-9]{1,3}/
  IP_IPADDR_REGEX = /inet (#{IPADDR_REGEX})/

  attr_accessor :id, :bootproto, :ipaddr, :vendor, :type
  attr_accessor :bridge_ports # default: set BRIDGE to "yes" in NETWORK.pm
  attr_accessor :vlan_etherdevice, :vlan_id
  attr_accessor :bond_slaves, :bond_slaves # default: set BOND_MASTER to "yes" in NETWORK.pm

  validates_format_of :id, :allow_nil => false, :with => /^[a-zA-Z0-9_-]+$/
  validates_inclusion_of :bootproto, :in => ["static","dhcp"]
  validates_format_of :ipaddr, :allow_blank => true, :with => /^#{IPADDR_REGEX}\/(#{IPADDR_REGEX}|[0-9]{1,2})$/  #(bnc#600097)

  public

  def ip
    ip = (self.ipaddr.blank?)? "" : self.ipaddr.split("/")[0]
  end

  #TODO: Netmask to CIDR
  #TODO: CIDR to Netmask
  def cidr
    # return netmask with slash or without slash ???
    #netmask = (self.ipaddr.blank?)? " " : "/#{self.ipaddr.split("/")[1]}"
    cidr =  (self.ipaddr.blank?)? "" : self.ipaddr.split("/")[1]
  end

  def netmask
    netmask = (self.cidr.blank?)? "" : IPAddr.new('255.255.255.255').mask(self.cidr).to_s
  end

  def initialize(args, id=nil)
    super args
    @id ||= id

    # use /sbin/ip to detect the ip address if bootproto == 'dhcp' (Justus Winter)
    if bootproto == "dhcp"
      stdout, stderr, status = Open3.popen3("/sbin/ip", "-o", "-family", "inet", "addr", "show", "dev", id) do |stdin, stdout, stderr|
        match = IP_IPADDR_REGEX.match(stdout.read())
        @ipaddr = (match)? match[1] : ""
      end
    else
      @ipaddr = ipaddr
    end

    @bridge_ports = bridge_ports.split(" ") unless bridge_ports.blank?

  end

  def self.find( which )
    YastCache.fetch(self, which) do
      response = YastService.Call("YaPI::NETWORK::Read")
      ifaces_h = response["interfaces"]

      if which == :all
        ret = Hash.new
        ifaces_h.each do |id, ifaces_h|
          ret[id] = Interface.new(ifaces_h, id)
        end
      else
        ret = Interface.new(ifaces_h[which], which)
      end

      Rails.logger.error ret.inspect 
      ret
    end
  end


  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set). ????????
  def destroy
    settings = { @id=>{} }
    settings = { @id => { "delete" => "true" }}
    vsettings = [ "a{sa{ss}}", settings ]
    
    response = YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})
    Rails.logger.error "\n *** DELETE INTERFACE  #{response.inspect}"

    YastCache.reset(self,@id)
    return true
   end

  # Saves data from model to system via YaPI. Saves only setted data,
  # so it support partial safe (e.g. save only new timezone if rest of fields is not set). ????????
  def update
    settings = { @id=>{} }

    if self.type == "vlan"
      Rails.logger.error "*** VLAN Settings ..."

      @vlan_id = self.vlan_id || ""
      @vlan_etherdevice = self.vlan_etherdevice || ""

      settings = {
        @id => {
        "bootproto" => @bootproto,
        "ipaddr" => @ipaddr,
        "vlan_id" => @vlan_id,
        "vlan_etherdevice" => @vlan_etherdevice,
        }
      }

    elsif self.type="bridge"
      @bridge_ports = self.bridge_ports || ""
      Rails.logger.error "*** Bridge Settings ... #{@bridge_ports.inspect}"

      settings = {
        @id => {
        "bootproto" => @bootproto,
        "ipaddr" => @ipaddr,
        "bridge" => "yes",
        "bridge_ports" => @bridge_ports,
        }
      }

    elsif self.type="eth"
      Rails.logger.error "*** Ethernet Settings ..."

      settings = {
        @id => {
          "bootproto" => @bootproto,
          "ipaddr" => @ipaddr
        }
      }

    end

#    if @bootproto.empty?
#      settings = { @id=>{} }
#    else
#      @vlan_id = @vlan_id || ""
#      @vlan_etherdevice = @vlan_etherdevice || ""

#      settings = {
#        @id => {
#        "bootproto" => @bootproto,
#        "ipaddr" => @ipaddr,
#        "vlan_id" => @vlan_id,
#        "vlan_etherdevice" => @vlan_etherdevice,
#        }
#      }
#    end

    Rails.logger.error "\n *** WRITE INTERFACE SETTING  #{settings.inspect}"

    vsettings = [ "a{sa{ss}}", settings ] # bnc#538050
    response = YastService.Call("YaPI::NETWORK::Write",{"interface" => vsettings})

    # TODO success or not?
    YastCache.reset(self,@id)
  end

end
