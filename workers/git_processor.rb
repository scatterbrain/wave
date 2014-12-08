require 'sneakers'
require 'json'
require 'rugged'

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

  Sneakers.logger.level = Logger::INFO 

  def work_with_params(msg, delivery_info, metadata)
    commit(JSON.parse(msg), repo())

    #Reply to delivery_info channel
    exchange = delivery_info.channel.default_exchange
    exchange.publish("ok", :routing_key => metadata.reply_to, :correlation_id => metadata.correlation_id)

    ack!
  end

  def repo()
    begin
      Rugged::Repository.new('/tmp/gitdo/')
    rescue
      Rugged::Repository.init_at('/tmp/gitdo/')
    end
  end

  def commit(msg, repo)
    oid = repo.write(msg["text"], :blob)
    index = repo.index
    begin
      index.read_tree(repo.head.target.tree)
    rescue
    end
    index.add(:path => "document.md", :oid => oid, :mode => 0100644)

    options = {}
    options[:tree] = index.write_tree(repo)

    options[:author] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:committer] = { :email => "mikko.a.hamalainen@gmail.com", :name => 'Mikko', :time => Time.now }
    options[:message] ||= "It's a commit!"
    options[:parents] = repo.empty? ? [] : [ repo.head.target ].compact
    options[:update_ref] = 'HEAD'

    Rugged::Commit.create(repo, options)
  end
end
