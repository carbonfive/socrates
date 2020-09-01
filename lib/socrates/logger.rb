require "logger"

module Socrates
  class Logger < ::Logger
    def self.default
      @default ||= begin
        logger       = new($stdout)
        logger.level = Logger::WARN
        logger
      end
    end
  end
end
