# -*- coding: utf-8 -*-
class BunnyMock::Channel
  attr_reader :queues, :exchanges
  def queue(name, attrs = {})
    @queues ||= []
    BunnyMock::Queue.new(name, attrs).tap { |q| @queues << q }
  end

  def exchange(name, attrs = {})
    @exchanges ||= []
    BunnyMock::Exchange.new(name, attrs).tap { |ex| @exchanges << ex }
  end
end
