require 'bunny'
require 'json'
require 'pp'
require 'thread'

class Publisher
  @@instance
  @@init = false

  def initialize
    return if @@init
    @@init = true

    @conn = Bunny.new(hostname: '192.168.56.1', user: 'root', password: 'root')
    @conn.start
  end

  def self.instance
    @@instance ||= Publisher.new
  end

  def connection
    @conn
  end

  def close
    @conn.close
  end
end
