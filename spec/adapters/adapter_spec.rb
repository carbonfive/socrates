require "spec_helper"

require "hashie/mash"

require "socrates/adapters/slack"

RSpec.describe Socrates::Adapters::Adapter do
  subject(:adapter) { Class.new { include Socrates::Adapters::Adapter }.new }

  describe "#client_id_from" do
  end

  describe "#channel_from" do
  end

  describe "#queue_message" do
  end

  describe "#queue_direct_message" do
  end

  describe "#flush_session" do
  end

  describe "#send_message" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.send_message("CH1", "Hark!")
      }.to raise_error NotImplementedError
    end
  end

  describe "#user_from" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.user_from(context: {})
      }.to raise_error NotImplementedError
    end
  end

  describe "#users" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.users
      }.to raise_error NotImplementedError
    end
  end

  describe "#lookup_user" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.lookup_user(email: "test@example.com")
      }.to raise_error NotImplementedError
    end
  end

  describe "#lookup_email" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.lookup_email
      }.to raise_error NotImplementedError
    end
  end
end
