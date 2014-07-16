# -*- coding: utf-8 -*-
require 'spec_helper'
require 'bunny_mock'

describe BunnyMock::Consumer do
  describe "#message_count" do
    Given(:consumer) { BunnyMock::Consumer.new(5) }
    Then { consumer.message_count.should == 5 }
  end
end
