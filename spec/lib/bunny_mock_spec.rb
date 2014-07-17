# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe BunnyMock do
  Given(:bunny) { BunnyMock.new }

  describe "#start" do
    Then { bunny.start.should == :connected }
  end

  describe "#qos" do
    Then { bunny.qos.should == :qos_ok }
  end

  describe "#stop" do
    Then { bunny.stop.should be_nil }
  end

  describe "#channels" do
    context "at the start" do
      Then { bunny.channels.should be_an Array }
      Then { bunny.channels.should be_empty }
    end
    context "adding channels" do
      When(:channel) { bunny.create_channel }
      Then { bunny.channels.count.should == 1 }
    end
    describe "channel queues" do
      Given(:c) { bunny.create_channel }
      When(:queues) {
        c.queue("foo", {:bar => :baz})
      }
      Then { c.queues.first.should be_a BunnyMock::Queue }
    end
  end

  describe "#queue" do
    When(:queue) { bunny.queue("my_queue", :durable => true) }
    Then { queue.should be_a BunnyMock::Queue }
    Then { queue.name.should == "my_queue" }
    Then { queue.should be_durable }
  end

  describe "#exchange" do
    When(:exchange) { bunny.exchange("my_exch", :type => :direct) }
    Then { exchange.should be_a BunnyMock::Exchange }
    Then { exchange.name.should == "my_exch" }
    Then { exchange.type.should == :direct }
  end
end
