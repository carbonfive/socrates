module Socrates
  module Config
    extend self

    attr_accessor :view_path
    attr_accessor :storage
    attr_accessor :error_message
    attr_accessor :expired_timeout # seconds
    attr_accessor :logger
  end

  class << self
    def configure
      block_given? ? yield(Config) : Config
    end

    def config
      Config
    end
  end
end
