require 'logger'

module Qmore::Persistence
  class Monitor
    attr_reader :updating, :interval
    # @param [Qmore::persistence] persistence - responsible for reading the configuration
    # from some source (redis, file, db, etc)
    # @param [Integer] interval - the period, in seconds, to wait between updates to the configuration.
    # defaults to 1 minute
    def initialize(persistence, interval, logger = nil)
      @persistence = persistence
      @interval = interval
      @logger = logger || (
        logger = Logger.new(STDOUT)
        logger.level = Logger::WARN
        logger
      )
    end

    def start
      return if @updating
      @updating = true

      # Ensure we load the configuration once from persistence before
      # the background thread.
      Qmore.configuration = @persistence.load

      Thread.new do
        while(@updating) do
          sleep @interval
          begin
            Qmore.configuration = @persistence.load
          rescue => e
            @logger.error "#{e.class.name} : #{e.message}"
          end
        end
      end
    end

    def stop
      @updating = false
    end
  end

  class Reqless
    DYNAMIC_QUEUE_KEY = "qmore:dynamic".freeze
    PRIORITY_KEY = "qmore:priority".freeze

    attr_reader :reqless

    def initialize(reqless)
      @reqless = reqless
    end

    # Returns a Qmore::Configuration from the underlying data storage mechanism
    # @return [Qmore::Configuration]
    def load
      configuration = Qmore::Configuration.new
      configuration.dynamic_queues = self.get_queue_identifier_patterns
      configuration.priority_buckets = self.get_queue_priority_patterns
      configuration
    end

    # Writes out the configuration to the underlying data storage mechanism.
    # @param[Qmore::Configuration] configuration to be persisted
    def write(configuration)
      set_queue_identifier_patterns(configuration.dynamic_queues)
      set_queue_priority_patterns(configuration.priority_buckets)
    end

    def get_queue_identifier_patterns
      reqless.queue_patterns.get_queue_identifier_patterns
    end

    def get_queue_priority_patterns
      reqless.queue_patterns.get_queue_priority_patterns
    end

    def set_queue_priority_patterns(data)
      reqless.queue_patterns.set_queue_priority_patterns(data)
    end

    def set_queue_identifier_patterns(dynamic_queues)
      reqless.queue_patterns.set_queue_identifier_patterns(dynamic_queues)
    end
  end
end
