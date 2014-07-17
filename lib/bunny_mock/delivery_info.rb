# -*- coding: utf-8 -*-
class BunnyMock::DeliveryInfo
  def initialize
    @@count ||= 0
    @@count += 1
    @count = @@count
  end

  # create uniq_id in spec
  def delivery_tag
    @count.to_s
  end

  def self.clear_delivery_tag
    @@count = 0
  end
end
