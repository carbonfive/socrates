require "spec_helper"

require "hashie/mash"

require "socrates/adapters/adapter"
require "socrates/core/session"

RSpec.describe Socrates::Adapters::Adapter do
  subject(:adapter) { Class.new { include Socrates::Adapters::Adapter }.new }

  describe "#client_id_from" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.client_id_from
      }.to raise_error NotImplementedError
    end
  end

  describe "#channel_from" do
    it "should raise an error because there isn't a default implementation" do
      expect {
        adapter.channel_from
      }.to raise_error NotImplementedError
    end
  end

  describe "#queue_message" do
    let(:channel) { "C1" }
    let(:session) { Socrates::Core::Session.new(client_id: "ABC", user: nil, channel: channel) }

    context "when send_now is false" do
      it "queues the messages in the session when send_now is false" do
        adapter.queue_message(session, "Got the power?", send_now: false)
        expect(session.messages[channel]).to eq ["Got the power?"]
      end
    end

    context "when send_now is true" do
      it "queues the message and flushes all messages for the channel" do
        expect(adapter).to receive(:flush_session).with(session, channel: channel)
        adapter.queue_message(session, "Got the power?", send_now: true)
      end
    end
  end

  describe "#queue_direct_message" do
    let(:channel) { "C1" }
    let(:session) { Socrates::Core::Session.new(client_id: "ABC", user: nil, channel: channel) }
    let(:recipient) { Socrates::Adapters::User.new(0, "", "", nil) }

    it "should queue the message in the recipient's channel" do
      expect(adapter).to receive(:channel_from).with(user: recipient).and_return("DM1")
      adapter.queue_direct_message(session, "What's up?", recipient)
      expect(session.messages["DM1"]).to eq ["What's up?"]
    end
  end

  describe "#flush_session" do
    let(:session) do
      session = Socrates::Core::Session.new(client_id: "ABC", user: nil, channel: "A")
      session.messages["A"] << "A1"
      session.messages["A"] << "A2"
      session.messages["B"] << "B1"
      session
    end

    context "when no channel is specified" do
      it "concatenates each channels messages and sends them" do
        expect(adapter).to receive(:send_message).with("A", "A1\n\nA2")
        expect(adapter).to receive(:send_message).with("B", "B1")

        adapter.flush_session(session)

        expect(session.messages["A"]).to be_empty
        expect(session.messages["B"]).to be_empty
      end
    end

    context "when a channel is specified" do
      it "concatenates all messages only for the channel and sends them" do
        expect(adapter).to receive(:send_message).with("A", "A1\n\nA2")
        expect(adapter).to_not receive(:send_message).with("B", "B1")

        adapter.flush_session(session, channel: "A")

        expect(session.messages["A"]).to be_empty
        expect(session.messages["B"]).to_not be_empty
      end
    end
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
