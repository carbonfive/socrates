require 'spec_helper'

require 'socrates/storage/storage'
require 'socrates/core/dispatcher'
require 'socrates/sample_states'

class NullLogger < Logger
  def initialize(*_args); end
  def add(*_args, &_block); end
end

RSpec.describe Socrates::Core::Dispatcher do
  # This spec runs through the prepackaged conversational ui as defined in SampleStates, starting with :get_started.

  before do
    Socrates.configure do |config|
      config.logger = NullLogger.new
    end
  end

  let(:adapter) { MemoryAdapter.new }
  let(:state_factory) { Socrates::SampleStates::StateFactory.new }

  subject(:dispatcher) {
    described_class.new(adapter: adapter, state_factory: state_factory)
  }

  it "runs through a sample 'happy path' conversation" do
    # Check that we're in the expected 'home' state.
    dispatcher.dispatch(message: "help")
    expect(adapter.last_message).to match("`age`").and match("`help`")

    dispatcher.dispatch(message: "age")
    expect(adapter.last_message).to eq "First things first, what's your name?"

    dispatcher.dispatch(message: "Christian Nelson")
    expect(adapter.last_message).to eq "Hi Christian! What's your birth date (e.g. MM/DD/YYYY)?"

    dispatcher.dispatch(message: "garbage!")
    expect(adapter.last_message).to eq "Whoops, I didn't get that. Can you try again? What's your birth date (e.g. MM/DD/YYYY)?"

    dispatcher.dispatch(message: "05/18/1974")
    expect(adapter.history[-3]).to eq "Got it Christian! So that makes you 42 years old."
    expect(adapter.history[-2]).to eq "That's all for now..."
    expect(adapter.history[-1]).to eq "Type `help` to see what else I can do."

    # Check that we're back in the expected 'home' state.
    dispatcher.dispatch(message: "help")
    expect(adapter.last_message).to match("`age`").and match("`help`")

    # And that we handle some random input.
    dispatcher.dispatch(message: "Howdy!")
    expect(adapter.last_message).to eq "Whoops, I don't know what you mean by that. Try `help` to see my commands."
  end

  it "recovers from an unexpected error while invoking a state action" do
    dispatcher.dispatch(message: "error")
    expect(adapter.last_message).to eq "I will raise an error regardless of what you enter next..."

    dispatcher.dispatch(message: "boom")
    expect(adapter.last_message).to eq "Sorry, an error occurred. We'll have to start over..."

    # Check that we're back in the expected 'home' state.
    dispatcher.dispatch(message: "help")
    expect(adapter.last_message).to match("`age`").and match("`help`")
  end
end
