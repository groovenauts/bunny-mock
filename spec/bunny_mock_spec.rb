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

describe BunnyMock::Consumer do
  describe "#message_count" do
    Given(:consumer) { BunnyMock::Consumer.new(5) }
    Then { consumer.message_count.should == 5 }
  end
end

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
