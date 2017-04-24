# Socrates
require "socrates/version"
require "socrates/config"
require "socrates/logger"
require "socrates/string_helpers"
require "socrates/adapters/console_adapter"
require "socrates/adapters/memory_adapter"
require "socrates/adapters/slack_adapter"
require "socrates/adapters/stubs"
require "socrates/storage/storage"
require "socrates/core/state_data"
require "socrates/core/state"
require "socrates/core/dispatcher"

# Bot implementations
require "socrates/bots/cli_bot"
require "socrates/bots/slack_bot"

module Socrates
end
