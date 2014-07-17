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
    bunny.channels.should be_empty
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
    expect(queue.messages[0][:delivery_info].delivery_tag).to eq("1")
    expect(queue.messages[0][:properties].to_hash.empty?).to be_true
    expect(queue.messages[0][:payload]).to eq('Message 1')

    expect(queue.messages[1][:delivery_info].delivery_tag).to eq("2")
    expect(queue.messages[1][:properties].to_hash.empty?).to be_true
    expect(queue.messages[1][:payload]).to eq('Message 2')

    expect(queue.messages[2][:delivery_info].delivery_tag).to eq("3")
    expect(queue.messages[2][:properties].to_hash.empty?).to be_true
    expect(queue.messages[2][:payload]).to eq('Message 3')

    queue.snapshot_messages.should have(3).messages
    expect(queue.snapshot_messages[0][:delivery_info].delivery_tag).to eq("1")
    expect(queue.snapshot_messages[0][:properties].to_hash.empty?).to be_true
    expect(queue.snapshot_messages[0][:payload]).to eq('Message 1')

    expect(queue.snapshot_messages[1][:delivery_info].delivery_tag).to eq("2")
    expect(queue.snapshot_messages[1][:properties].to_hash.empty?).to be_true
    expect(queue.snapshot_messages[1][:payload]).to eq('Message 2')

    expect(queue.snapshot_messages[2][:delivery_info].delivery_tag).to eq("3")
    expect(queue.snapshot_messages[2][:properties].to_hash.empty?).to be_true
    expect(queue.snapshot_messages[2][:payload]).to eq('Message 3')


    # Here's what we expect to happen when we subscribe to this queue.
    handler = double("target")
    delivery_info = BunnyMock::DeliveryInfo.new

    handler.should_receive(:handle_message).with(any_args) do |delivery_info, properties, payload|
      delivery_info.delivery_tag == '1' && properties == {} && payload == 'Message 1'
    end.ordered

    handler.should_receive(:handle_message).with(any_args) do |delivery_info, properties, payload|
      delivery_info.delivery_tag == '2' && properties == {} && payload == 'Message 2'
    end.ordered

    handler.should_receive(:handle_message).with(any_args) do |delivery_info, properties, payload|
      delivery_info.delivery_tag == '3' && properties == {} && payload == 'Message 3'
    end.ordered


    # Read all those messagesX
    msg_count = 0
    queue.subscribe do |delivery_info, properties, payload|
      handler.handle_message(delivery_info, properties, payload)
      msg_count += 1
      queue.default_consumer.message_count.should == msg_count
    end
  end
end
