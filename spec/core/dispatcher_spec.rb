require "spec_helper"

require "timecop"

require "socrates/adapters/memory"
require "socrates/storage/memory"
require "socrates/core/dispatcher"
require "socrates/sample_states"

RSpec.describe Socrates::Core::Dispatcher do
  # This spec runs through the prepackaged conversational ui as defined in SampleStates, starting with :get_started.

  before do
    Socrates.configure do |config|
      config.logger.level    = Logger::FATAL
      config.error_message   = "Whoops! Time for a reboot..."
      config.expired_timeout = 120
    end

    storage.clear_all

    Timecop.travel(Date.new(2017, 4, 22))
  end

  after do
    Timecop.return
  end

  let(:adapter) { Socrates::Adapters::Memory.new }
  let(:storage) { Socrates::Storage::Memory.new }
  let(:state_factory) { Socrates::SampleStates::StateFactory.new }
  subject(:dispatcher) { described_class.new(adapter: adapter, storage: storage, state_factory: state_factory) }

  context "given the set of sample states and transitions" do
    describe "#dispatch" do
      it "navigates a happy path conversation starting with the 'age' command" do
        # Check that we're in the expected 'home' state.
        dispatcher.dispatch("help")
        expect(adapter.last_msg).to match("`age`").and match("`help`")

        # Handle yelling with grace.
        dispatcher.dispatch("AGE")
        expect(adapter.last_msg).to eq "First things first, what's your name?"

        dispatcher.dispatch("Christian Nelson")
        expect(adapter.last_msg).to eq "Hi Christian! What's your birth date (e.g. MM/DD/YYYY)?"

        dispatcher.dispatch("garbage!")
        expect(adapter.last_msg).to eq "Whoops, I didn't understand that. What's your birth date (e.g. MM/DD/YYYY)?"

        dispatcher.dispatch("05/18/1974")
        expect(adapter.msgs[-3]).to eq "Got it Christian! So that makes you 42 years old."
        expect(adapter.msgs[-2]).to eq "That's all for now..."
        expect(adapter.msgs[-1]).to eq "Type `help` to see what else I can do."

        # Check that we're back in the expected 'home' state.
        dispatcher.dispatch("help")
        expect(adapter.last_msg).to match("`age`").and match("`help`")

        # And that we handle some random input.
        dispatcher.dispatch("Howdy!")
        expect(adapter.last_msg).to eq "Whoops, I don't know what you mean by that. Try `help` to see my commands."
      end

      it "transitions to the expired state when too much time has passed" do
        dispatcher.dispatch("age")
        expect(adapter.last_msg).to eq "First things first, what's your name?"

        # Trigger an expiration.
        Timecop.travel(121.seconds.from_now)
        dispatcher.dispatch("Bob Smith")
        expect(adapter.msgs[-2]).to eq "I've forgotten what we're talking about, let's start over."
      end

      it "recovers from an unexpected error while invoking a state action" do
        dispatcher.dispatch("error")
        expect(adapter.last_msg).to eq "I will raise an error regardless of what you enter next..."

        dispatcher.dispatch("boom")
        expect(adapter.last_msg).to eq "Whoops! Time for a reboot..."

        # Check that we're back in the expected 'home' state.
        dispatcher.dispatch("help")
        expect(adapter.last_msg).to match("`age`").and match("`help`")
      end
    end

    describe "#start_conversation" do # TODO: trigger_conversation?
      let(:user) { Socrates::Adapters::User.new("U123", "username", 0, nil) }

      context "when the user has not yet participated in a conversation" do
        it "returns true to indicate success" do
          expect(dispatcher.start_conversation(user, :ask_for_name)).to be true
        end

        it "starts a new conversation in the specified state" do
          dispatcher.start_conversation(user, :ask_for_name)

          expect(dispatcher.conversation_state(user).state_id).to eq :ask_for_name
        end

        it "runs the :ask action and sends the corresponding outputs to the target user" do
          dispatcher.start_conversation(user, :ask_for_name)

          expect(adapter.last_dm("U123")).to include "First things first, what's your name?"
        end
      end

      context "when the user's conversation has expired" do
        before do
          dispatcher.dispatch("age")
          dispatcher.dispatch("Mister Mister") # leaves conversation in the :ask_for_birth_date state
          Timecop.travel(121.seconds.from_now)
        end

        it "returns true to indicate success" do
          expect(dispatcher.start_conversation(user, :ask_for_name)).to be true
        end

        it "starts a new conversation in the specified state" do
          dispatcher.start_conversation(user, :ask_for_name)

          expect(dispatcher.conversation_state(user).state_id).to eq :ask_for_name
        end

        it "runs the :ask action and sends the corresponding outputs to the target user" do
          dispatcher.start_conversation(user, :ask_for_name)

          expect(adapter.last_dm("U123")).to include "First things first, what's your name?"
        end
      end

      context "when the user is actively participating in a conversation" do
        before do
          dispatcher.dispatch("age")
          dispatcher.dispatch("Mister Mister") # leaves conversation in the :ask_for_birth_date state
        end

        it "returns false" do
          expect(dispatcher.start_conversation(user, :ask_for_name)).to be false
        end

        it "does not change the state" do
          expect(dispatcher.conversation_state(user).state_id).to eq :ask_for_birth_date
        end
      end
    end

    describe "#conversation_state" do
      let(:user) { Socrates::Adapters::User.new("U123", "username", 0, nil) }

      context "when the user has not yet participated in a conversation" do
        it "returns nil" do
          state = dispatcher.conversation_state(user)
          expect(state).to be_nil
        end
      end

      context "when the user's conversation has expired" do
        before do
          dispatcher.dispatch("age")
          dispatcher.dispatch("Mister Mister")
          Timecop.travel(121.seconds.from_now)
        end

        it "returns nil" do
          state = dispatcher.conversation_state(user)
          expect(state).to be_nil
        end
      end

      context "when the user is actively participating in a conversation" do
        before do
          dispatcher.dispatch("age")
          dispatcher.dispatch("Mister Mister") # leaves conversation in the :ask_for_birth_date state
        end

        it "returns the conversation state" do
          state = dispatcher.conversation_state(user)
          expect(state).not_to be_nil
          expect(state.state_id).to eq :ask_for_birth_date
        end
      end
    end
  end
end
