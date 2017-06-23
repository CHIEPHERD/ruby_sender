require 'bunny'
require 'json'
require 'pp'
require 'thread'
require_relative 'publisher'

class RPC
  attr_accessor :response, :call_id

  def initialize
    @publisher = Publisher.instance

    @lock = Mutex.new
    @condition = ConditionVariable.new

    @channel  = @publisher.connection.create_channel
    @exchange = @channel.topic('chiepherd.main', durable: true)

    @reply_queue = @channel.queue('', exclusive: true)
    puts "RPQ " + @reply_queue.name
    @routing_key = 'chiepherd.task.list'

    that = self
    @reply_queue.subscribe do |delivery_info, properties, payload|
      puts " Response 73657342q"
      if properties[:correlation_id] == that.call_id
        that.response = payload
        @lock.synchronize { @condition.signal }
      end
    end
  end

  def call(msg)
    self.call_id = generate_uuid

    @exchange.publish(msg, routing_key: @routing_key,
                           correlation_id: self.call_id,
                           reply_to: @reply_queue.name)
    @lock.synchronize{@condition.wait(@lock)}
    response
  end

  protected

  def generate_uuid
    # very naive but good enough for code
    # examples
    "#{rand}#{rand}#{rand}"
  end
end


msg = {
  uuid: '24e18762-671e-46dd-9f8e-2f9d5186a921',
  projectId: 1
}.to_json
pp RPC.new.call(msg)
