# -*- coding: utf-8 -*-
require 'bunny'

class BunnyMock::Exchange
  attr_accessor :name, :attrs, :queues
  def initialize(name, attrs = {})
    self.name   = name
    self.attrs  = attrs.dup
    self.queues = []
  end

  def publish(payload, properties = {})
    message_properties = Bunny::MessageProperties.new(properties)
    delivery_info      = BunnyMock::DeliveryInfo.new

    message = {delivery_info: delivery_info, properties: message_properties , payload: payload, }

    queues.each { |q| q.messages << message }
  end

  def bound_to?(queue_name)
    queues.any?{|q| q.name == queue_name}
  end

  def method_missing(method, *args)
    method_name  = method.to_s
    is_predicate = false
    if method_name =~ /^(.*)\?$/
      key           = $1.to_sym
      is_predicate = true
    else
      key = method.to_sym
    end

    if attrs.has_key? key
      value = attrs[key]
      is_predicate ? !!value : value
    else
      super
    end
  end
end

