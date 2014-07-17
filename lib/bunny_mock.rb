require "bunny_mock/version"
require 'bunny_mock/consumer'
require 'bunny_mock/channel'
require 'bunny_mock/exchange'
require 'bunny_mock/queue'
require 'bunny_mock/delivery_info'

class BunnyMock

  def start
    :connected
  end

  def qos
    :qos_ok
  end

  def stop
    nil
  end

  def channels
    @channels ||= []
  end

  def create_channel
    Channel.new.tap{|c| channels << c}
  end

  def queue(*attrs)
    BunnyMock::Queue.new(*attrs)
  end

  def exchange(*attrs)
    BunnyMock::Exchange.new(*attrs)
  end
end
