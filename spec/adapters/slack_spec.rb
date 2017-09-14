require "spec_helper"

require "hashie/mash"

require "socrates/adapters/slack"

RSpec.describe Socrates::Adapters::Slack do
  let(:web_client) { double }
  let(:real_time_client) { double(web_client: web_client) }
  subject(:adapter) { described_class.new(real_time_client) }

  describe "#client_id_from" do
    it "raises an exception if context and user are nil" do
      expect {
        adapter.client_id_from
      }.to raise_error ArgumentError, "Must provide one of context or user"

      expect {
        adapter.client_id_from(context: nil, user: nil)
      }.to raise_error ArgumentError, "Must provide one of context or user"
    end

    it "raises an exception if the context does not respond to :user" do
      expect {
        adapter.client_id_from(context: Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected context to respond to :user"
    end

    it "raises an exception if the user does not respond to :id" do
      expect {
        adapter.client_id_from(user: Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected user to respond to :id"
    end

    it "extracts the user from the context" do
      slack_context = Hashie::Mash.new(user: "U123ABC")
      expect(adapter.client_id_from(context: slack_context)).to eq "U123ABC"
    end

    it "extracts the id from the user" do
      slack_user = Hashie::Mash.new(id: "U123")
      expect(adapter.client_id_from(user: slack_user)).to eq "U123"
    end
  end

  describe "#channel_from" do
    it "raises an exception if context and user are nil" do
      expect {
        adapter.channel_from
      }.to raise_error ArgumentError, "Must provide one of context or user"

      expect {
        adapter.channel_from(context: nil, user: nil)
      }.to raise_error ArgumentError, "Must provide one of context or user"
    end

    it "raises an exception if the context does not respond to :channel" do
      expect {
        adapter.channel_from(context: Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected context to respond to :channel"
    end
  end

  describe "#user_from" do
    it "raises an exception if context is nil" do
      expect {
        adapter.user_from(context: nil)
      }.to raise_error ArgumentError, "context cannot be nil"
    end

    it "raises an exception if the context does not respond to :user" do
      expect {
        adapter.user_from(context: Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected context to respond to :user"
    end
  end

  describe "#send_message" do
    it "raises an exception when the session is nil" do
      expect {
        adapter.send_message(nil, "yo")
      }.to raise_error ArgumentError, "session is required"
    end

    it "raises an exception when the session does not contain a channel" do
      expect {
        session = Socrates::Core::Session.new(channel: nil)
        adapter.send_message(session, "yo")
      }.to raise_error ArgumentError, "session.channel is required"
    end
  end

  describe "#send_direct_message" do
    it "raises an exception when user does not respond to :id" do
      expect {
        adapter.send_direct_message(nil, "yo", Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected recipient to respond to :id"
    end
  end

  describe "#users_list" do
    let(:active_members) { [Hashie::Mash.new(id: "AM01", deleted: false, is_bot: false)] }
    let(:deleted_members) { [Hashie::Mash.new(id: "D01", deleted: true, is_bot: false)] }
    let(:bots) { [Hashie::Mash.new(id: "B01", deleted: false, is_bot: true)] }
    let(:all_members) { active_members + deleted_members + bots }

    before do
      expect(web_client).to receive(:users_list).and_return(double(members: all_members))
    end

    it "removes deleted users and bots by default" do
      expect(adapter.users_list.members).to contain_exactly(*active_members)
    end

    it "includes deleted users when include_deleted is true" do
      expect(adapter.users_list(include_deleted: true).members).to contain_exactly(*(active_members + deleted_members))
    end

    it "includes bots when include_bots is true" do
      expect(adapter.users_list(include_bots: true).members).to contain_exactly(*(active_members + bots))
    end
  end

  describe "#lookup_email" do
    it "raises an exception when context does not respond to :user" do
      expect {
        adapter.lookup_email(context: Hashie::Mash.new)
      }.to raise_error ArgumentError, "Expected context to respond to :user"
    end

    it "returns the user's email address when it's present in the profile" do
      slack_context = Hashie::Mash.new(user: "U123")
      info          = Hashie::Mash.new(user: { profile: { email: "pat@example.com" } })

      expect(web_client).to receive(:users_info).with(user: "U123").and_return(info)

      expect(adapter.lookup_email(context: slack_context)).to eq "pat@example.com"
    end

    it "returns nil if the user does not have an email" do
      slack_context = Hashie::Mash.new(user: "U123")
      info          = Hashie::Mash.new(user: { profile: { email: "" } })

      expect(web_client).to receive(:users_info).with(user: "U123").and_return(info)

      expect(adapter.lookup_email(context: slack_context)).to be_nil
    end
  end
end
