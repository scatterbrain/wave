require 'sneakers'
require 'json'

class GitProcessor
  include Sneakers::Worker
  from_queue "doc.request", 
      env: nil, #Env nil tells not to mangle the name to doc.request_development
      :durable => true

    #from_queue 'downloads',
    #         :durable => false,
    #         :ack => true,
    #         :threads => 50,
    #         :prefetch => 50,
    #         :timeout_job_after => 1,
    #         :exchange => 'dummy',
    #         :heartbeat => 5

  Sneakers.configure({})

#  Sneakers.configure(:handler => Sneakers::Handlers::Maxretry,
#                   :workers => 1,
#                   :threads => 1,
#                   :prefetch => 1,
#                   :exchange => 'sneakers',
#                   :exchange_type => 'topic', ##NOTE WE CAN MAKE A TOPIC
  #                   EXCHANGE!
#                   :routing_key => ['#', 'something'],
#                   :durable => true,
#                   )

  Sneakers.logger.level = Logger::DEBUG #Logger::INFO # the default DEBUG is too noisy

  def work_with_params(msg, delivery_info, metadata)
    puts "GOT A MESSAGE #{msg.inspect} Delivery: #{delivery_info.inspect} Metadata: #{metadata.inspect}" 

    #Reply to delivery_info channel
    exchange = delivery_info.channel.default_exchange
    exchange.publish("HEI EI", :routing_key => metadata.reply_to, :correlation_id => metadata.correlation_id)

    ack!
  end
end
