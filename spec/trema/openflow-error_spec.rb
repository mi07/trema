#
# Author: Nick Karanatsios <nickkaranatsios@gmail.com>
#
# Copyright (C) 2008-2012 NEC Corporation
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#


require File.join( File.dirname( __FILE__ ), "..", "spec_helper" )
require "trema"


describe Trema::OpenflowError, "new" do
  context "when #port_mod with an invalid(port_no) is sent" do
    it "should receive #error(type=Error::OFPET_PORT_MOD_FAILED,code=Error::OFPPMFC_BAD_PORT)" do
      class OpenflowErrorController < Controller; end
      network {
        vswitch { datapath_id 0xabc }
      }.run( OpenflowErrorController ) {
        port_mod = Trema::PortMod.new( :port_no => 2, 
          :hw_addr => Trema::Mac.new( "11:22:33:44:55:66" ),
          :config => 1,
          :mask => 1,
          :advertise => 0
        )
        controller( "OpenflowErrorController" ).send_message( 0xabc, port_mod )
        controller( "OpenflowErrorController" ).should_receive( :openflow_error ) do | arg |
          arg.datapath_id.should == 0xabc
          arg.type.should == Error::OFPET_PORT_MOD_FAILED
          arg.code.should == Error::OFPPMFC_BAD_PORT 
        end
      }
    end
  end
  
  
  context "when #port_mod with an invalid(hw_addr) is sent" do
    it "should receive #error(type=Error::OFPET_PORT_MOD_FAILED,code=Error::OFPPMFC_BAD_HW_ADDR)" do
      class OpenflowErrorController < Controller; end
      network {
        vswitch( "error-hw-addr") { datapath_id 0xabc }
        vhost "host1"
        vhost "host2"
        link "host1", "error-hw-addr"
        link "host2", "error-hw-addr"
      }.run( OpenflowErrorController ) {
        port_mod = Trema::PortMod.new( :port_no => 1, 
          :hw_addr => Trema::Mac.new( "11:22:33:44:55:66" ),
          :config => 1,
          :mask => 1,
          :advertise => 0
        )
        controller( "OpenflowErrorController" ).send_message( 0xabc, port_mod )
        controller( "OpenflowErrorController" ).should_receive( :openflow_error ) do | arg |
          arg.datapath_id.should == 0xabc
          arg.type.should == Error::OFPET_PORT_MOD_FAILED
          arg.code.should == Error::OFPPMFC_BAD_HW_ADDR
        end
      }
    end
  end
  
  
  context "when #flow_mod(add) message with an invalid(action_port) is sent" do
    it "should receive #error(type=Error::OFPET_BAD_ACTION,code=Error::OFPBAC_BAD_OUT_PORT)" do
      class OpenflowErrorController < Controller; end
      network {
        vswitch( "error-port") { datapath_id 0xabc }
        vhost "host1"
        vhost "host2"
        link "host1", "error-port"
        link "host2", "error-port"
      }.run( OpenflowErrorController ) {
        controller( "OpenflowErrorController" ).send_flow_mod_add( 0xabc, :actions => ActionOutput.new( :port => 0x5555 ) )
        controller( "OpenflowErrorController" ).should_receive( :openflow_error ) do | arg |
          arg.datapath_id.should == 0xabc
          arg.type.should == Error::OFPET_BAD_ACTION
          arg.code.should == Error::OFPBAC_BAD_OUT_PORT
        end
      }
    end
  end
  
  
  context "when an unsupported message is sent" do  
    it "should receive an openflow error with valid attributes" do
      class OpenflowController < Controller; end
      network {
        vswitch { datapath_id 0xabc }
      }.run( OpenflowController ) {
        queue_get_config_request = Trema::QueueGetConfigRequest.new( :port => 1 )
        controller( "OpenflowController" ).send_message( 0xabc, queue_get_config_request )
        controller( "OpenflowController" ).should_receive( :openflow_error ) do | message |
          message.datapath_id.should == 0xabc
          message.type.should satisfy { | n |
            n >= 0 && n <= 5
          }
          case message.type
          when 0,4
            message.code.should include 0,1
          when 1,2
            message.code.should satisfy { | n | 
              n >= 0 && n <= 8
            }
          when 3
            message.code.should satisfy { | n |
              n >= 0 && n <= 5
            }
          when 5
            message.code.should satisfy { |n|
              n >= 0 && n <= 3
            }
          end
        end
      }
    end
  end
end


### Local variables:
### mode: Ruby
### coding: utf-8-unix
### indent-tabs-mode: nil
### End:
