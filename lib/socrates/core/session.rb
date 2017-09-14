require "socrates/configuration"

module Socrates
  module Core
    class Session
      attr_accessor :client_id, :user, :channel, :messages

      def initialize(client_id: nil, user: nil, channel: nil)
        @client_id = client_id
        @user      = user
        @channel   = channel
        @messages  = Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end
