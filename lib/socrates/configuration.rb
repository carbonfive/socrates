require "active_support/core_ext/numeric/time"
require "socrates/logger"
require "socrates/storage/memory"

module Socrates
  def self.config
    @config ||= Configuration.new
  end

  def self.configure
    yield(config)
  end

  class Configuration
    attr_accessor :view_path
    attr_accessor :storage
    attr_accessor :error_message
    attr_accessor :expired_timeout # seconds
    attr_accessor :logger
    attr_accessor :error_handler   # a callable like ->(String, Exception) { ... }
    attr_accessor :warn_handler    # a callable like ->(String) { ... }
    attr_accessor :event_handler   # a callable like ->(Session, Event, Data) { ... }

    def initialize
      @storage         = Storage::Memory.new
      @error_message   = "Sorry, something went wrong. We'll have to start over..."
      @expired_timeout = 30.minutes
      @logger          = Socrates::Logger.default
      @error_handler   = proc { |_message, _error| }
      @warn_handler    = proc { |_message| }
      @event_handler   = proc { |_session, event, data|
        puts ">>> #{event}: #{data.inspect}"
      }
    end
  end
end
