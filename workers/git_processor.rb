require 'sneakers'
require 'json'

class GitProcessor
  include Sneakers::Worker
  from_queue :logs

    #from_queue 'downloads',
    #         :durable => false,
    #         :ack => true,
    #         :threads => 50,
    #         :prefetch => 50,
    #         :timeout_job_after => 1,
    #         :exchange => 'dummy',
    #         :heartbeat => 5

  Sneakers.configure({})
  Sneakers.logger.level = Logger::INFO # the default DEBUG is too noisy

  def work(msg)
#    err = JSON.parse(msg)
#    if err["type"] == "error"
#      $redis.incr "processor:#{err["error"]}"
#    end
    puts "GOT A MESSAGE"
    ack!
  end
end
