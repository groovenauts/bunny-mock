# -*- coding: utf-8 -*-
class BunnyMock::Exchange
  attr_accessor :name, :attrs, :queues
  def initialize(name, attrs = {})
    self.name   = name
    self.attrs  = attrs.dup
    self.queues = []
  end

  def publish(msg, msg_attrs = {})
    queues.each { |q| q.messages << msg }
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

