# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe BunnyMock::Queue do
  Given(:queue_name) { "my_test_queue" }
  Given(:queue_attrs) {
    {
      :durable     => true,
      :auto_delete => true,
      :exclusive   => false,
      :arguments   => {"x-ha-policy" => "all"}
    }
  }
  Given(:queue) { BunnyMock::Queue.new(queue_name, queue_attrs) }

  describe "#name" do
    Then { queue.name.should == queue_name }
  end

  describe "#attrs" do
    Then { queue.attrs.should == queue_attrs }
  end

  describe "#messages" do
    Then { queue.messages.should be_an Array }
    Then { queue.messages.should be_empty }
  end

  describe "#snapshot_messages" do
    Then { queue.snapshot_messages.should be_an Array }
    Then { queue.snapshot_messages.should be_empty }
  end

  describe "#delivery_count" do
    Then { queue.delivery_count.should == 0 }
  end

  describe "#subscribe" do
    Given { queue.messages = [
        {delivery_info: BunnyMock::DeliveryInfo.new, properties: Bunny::MessageProperties.new({}), payload: 'Ehh'},
        {delivery_info: BunnyMock::DeliveryInfo.new, properties: Bunny::MessageProperties.new({}), payload: "What's up Doc?"}
      ] }
    Given(:handler) { double("handler") }
    Given {
      handler.should_receive(:handle).with(any_args) do |delivery_info, properties, payload|
        delivery_info.delivery_tag == '1' && properties == {} && payload == 'Ehh'
      end.ordered

      handler.should_receive(:handle).with(any_args) do |delivery_info, properties, payload|
        delivery_info.delivery_tag == '1' && properties == {} && payload == "What's up Doc?"
      end.ordered

    }
    When { queue.subscribe { |msg| handler.handle(msg) } }
    Then { queue.messages.should be_empty }
    Then { queue.snapshot_messages.should be_empty }
    Then { queue.delivery_count.should == 2 }
    Then { verify_mocks_for_rspec }
  end

  describe "#snapshot_messages" do
    Given { queue.messages = ["Ehh", "What's up Doc?"] }
    Then {
      snapshot = queue.snapshot_messages
      snapshot.should == ["Ehh", "What's up Doc?"]
      snapshot.shift
      snapshot << "Nothin"
      snapshot.should == ["What's up Doc?", "Nothin"]
      queue.messages.should == ["Ehh", "What's up Doc?"]
      queue.snapshot_messages.should == ["Ehh", "What's up Doc?"]
    }
  end

  describe "#bind" do
    Given(:exchange) { BunnyMock::Exchange.new("my_test_exchange",) }
    When { queue.bind(exchange) }
    Then { exchange.should be_bound_to "my_test_queue" }
  end

  describe "#default_consumer" do
    Given { queue.delivery_count = 5 }
    When(:consumer) { queue.default_consumer }
    Then { consumer.should be_a BunnyMock::Consumer }
    Then { consumer.message_count.should == 5 }
  end

  describe "#method_missing" do
    Then { queue.durable.should be_true }
    Then { queue.should be_durable }
    Then { queue.auto_delete.should be_true }
    Then { queue.should be_auto_delete }
    Then { queue.exclusive.should == false }
    Then { queue.should_not be_exclusive }
    Then { queue.arguments.should == {"x-ha-policy" => "all"} }
    Then { expect { queue.wtf }.to raise_error NoMethodError }
  end
end
