require 'bunny'
require 'json'
require 'pp'
require 'thread'
require_relative 'publisher'
require 'yaml'

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
    @routing_key = 'kanban.task.change_points'

    that = self
    @reply_queue.subscribe do |delivery_info, properties, payload|
      puts " Response 73657342q"
      if properties[:correlation_id] == that.call_id
        that.response = payload
        @lock.synchronize { @condition.signal }
      end
    end
  end

  def close
    @publisher.close
  end

  def call
    msg = YAML.load_file "messages/#{@routing_key.gsub('.', '/')}.yml"
    @exchange.publish(msg.to_json, routing_key: @routing_key,
                                correlation_id: self.call_id,
                                reply_to: @reply_queue.name)
    @lock.synchronize{@condition.wait(@lock)}
    response
  rescue
    @reply_queue.close
  end

  protected

  def generate_uuid
    "#{rand}#{rand}#{rand}"
  end
end


begin
  conn = RPC.new
  pp conn.call
rescue Interrupt
ensure
  puts 'Shutdown'
  conn.close
end
