# -*- coding: utf-8 -*-
class BunnyMock::Consumer
  attr_accessor :message_count
  def initialize(c)
    self.message_count = c
  end
end
