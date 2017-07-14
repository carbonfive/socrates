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

    def initialize
      @storage         = Storage::Memory.new
      @error_message   = "Sorry, something went wrong. We'll have to start over..."
      @expired_timeout = 30.minutes
      @logger          = Socrates::Logger.default
    end
  end
end
