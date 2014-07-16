# -*- coding: utf-8 -*-
class BunnyMock::Channel
  attr_reader :queues
  def queue(name, attrs = {})
    @queues ||= []
    BunnyMock::Queue.new(name, attrs).tap { |q| @queues << q }
  end
end
