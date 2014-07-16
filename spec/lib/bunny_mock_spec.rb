# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe "BunnyMock Integration Tests", :integration => true do
  it "should handle the basics of message passing" do
    # Basic one-to-one queue/exchange setup.
    bunny = BunnyMock.new
    queue = bunny.queue(
      "integration_queue",
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    )
    exchange = bunny.exchange(
      "integration_exchange",
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    )
    queue.bind(exchange)

    # Basic assertions
    queue.messages.should be_empty
    exchange.queues.should have(1).queue
    exchange.should be_bound_to "integration_queue"
    queue.default_consumer.message_count.should == 0

    # Send some messages
    exchange.publish("Message 1")
    exchange.publish("Message 2")
    exchange.publish("Message 3")

    # Verify state of the queue
    queue.messages.should have(3).messages
    queue.messages.should == [
      "Message 1",
      "Message 2",
      "Message 3"
    ]
    queue.snapshot_messages.should have(3).messages
    queue.snapshot_messages.should == [
      "Message 1",
      "Message 2",
      "Message 3"
    ]

    # Here's what we expect to happen when we subscribe to this queue.
    handler = mock("target")
    handler.should_receive(:handle_message).with("Message 1").ordered
    handler.should_receive(:handle_message).with("Message 2").ordered
    handler.should_receive(:handle_message).with("Message 3").ordered

    # Read all those messages
    msg_count = 0
    queue.subscribe do |msg|
      handler.handle_message(msg[:payload])
      msg_count += 1
      queue.default_consumer.message_count.should == msg_count
    end
  end
end

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
