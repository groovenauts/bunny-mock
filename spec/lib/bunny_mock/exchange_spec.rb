# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe BunnyMock::Exchange do
  Given(:exchange_name) { "my_test_exchange" }
  Given(:exchange_attrs) {
    {
      :type        => :direct,
      :durable     => true,
      :auto_delete => true
    }
  }
  Given(:exchange) { BunnyMock::Exchange.new(exchange_name, exchange_attrs) }

  describe "#name" do
    Then { exchange.name.should == exchange_name }
  end

  describe "#attrs" do
    Then { exchange.attrs.should == exchange_attrs }
  end

  describe "#queues" do
    context "when the exchange is not bound to any queues" do
      Then { exchange.queues.should be_an Array }
      Then { exchange.queues.should be_empty }
    end

    context "when the exchange is bound to a queue" do
      Given(:queue) { BunnyMock::Queue.new("a_queue") }
      Given { queue.bind(exchange) }
      Then { exchange.queues.should have(1).queue }
      Then { exchange.queues.first.should == queue }
    end
  end

  describe "#bound_to?" do
    Given(:queue) { BunnyMock::Queue.new("a_queue") }
    Given { queue.bind(exchange) }
    Then { exchange.should be_bound_to("a_queue") }
    Then { exchange.should_not be_bound_to("another_queue") }
  end

  describe "#publish" do
    Given(:queue1) { BunnyMock::Queue.new("queue1") }
    Given(:queue2) { BunnyMock::Queue.new("queue2") }
    Given { queue1.bind(exchange) }
    Given { queue2.bind(exchange) }
    When { BunnyMock::DeliveryInfo.clear_delivery_tag }
    When { exchange.publish("hello") }

    Then { expect(queue1.messages.size).to eq(1)}
    Then { expect(queue1.messages[0][:delivery_info].delivery_tag).to eq("1")}
    Then { expect(queue1.messages[0][:properties].to_hash.empty?).to be_true}
    Then { expect(queue1.messages[0][:payload]).to eq('hello')}
    Then { expect(queue1.snapshot_messages[0][:delivery_info].delivery_tag).to eq("1")}
    Then { expect(queue1.snapshot_messages[0][:properties].to_hash.empty?).to be_true}
    Then { expect(queue1.snapshot_messages[0][:payload]).to eq('hello')}

    Then { expect(queue2.messages.size).to eq(1)}
    Then { expect(queue2.messages[0][:delivery_info].delivery_tag).to eq("1")}
    Then { expect(queue2.messages[0][:properties].to_hash.empty?).to be_true}
    Then { expect(queue2.messages[0][:payload]).to eq('hello')}
    Then { expect(queue2.snapshot_messages[0][:delivery_info].delivery_tag).to eq("1")}
    Then { expect(queue2.snapshot_messages[0][:properties].to_hash.empty?).to be_true}
    Then { expect(queue2.snapshot_messages[0][:payload]).to eq('hello')}
  end

  describe "#method_missing" do
    Then { exchange.type.should == :direct }
    Then { exchange.durable.should be_true }
    Then { exchange.should be_durable }
    Then { exchange.auto_delete.should be_true }
    Then { exchange.should be_auto_delete }
    Then { expect { exchange.wtf }.to raise_error NoMethodError }
  end
end
