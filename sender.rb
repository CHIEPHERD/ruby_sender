require 'bunny'
require 'json'
require 'pp'
require 'thread'

conn = Bunny.new(hostname: '192.168.56.1', user: 'root', password: 'root')
conn.start
lock = Mutex.new

ch = conn.create_channel

x = ch.topic('chiepherd.main', durable: true)
queue = ch.queue("", exclusive: true)
msg = { name: 'Solaris',
        descridption: 'Power of God',
        label: 'Light',
        id: 1
      }

pp msg

# 5.times do
  x.publish(msg.to_json, routing_key: "chiepherd.project.create")
  sleep 0.10
  msg[:name] = 'Wizard'
  x.publish(msg.to_json, routing_key: "chiepherd.project.update", reply_to: 'chiepherd.project.update.success', correlation_id: generate_uuid)

  lock.synchronize { }
# end

conn.close

def generate_uuid
  # very naive but good enough for code
  # examples
  "#{rand}#{rand}#{rand}"
end
