require "spec_helper"

require "socrates/adapters/memory"
require "socrates/core/state"

class StateA
  include Socrates::Core::State

  def ask
  end

  def listen(_message)
  end
end

RSpec.describe Socrates::Core::State do
  describe "#respond" do
    let(:adapter) { Socrates::Adapters::Memory.new }
    let(:state_data) { Socrates::Core::StateData.new(state_id: :state_a, state_action: :ask) }
    subject(:state) { StateA.new(adapter: adapter, data: state_data) }

    context "when given a :message" do
      it "passes the string as-is to the adapter for sending" do
        state.respond message: "ABC987"

        expect(adapter.last_message).to eq "ABC987"
      end
    end

    context "when given a :template" do
      it "renders the template and sends the output to the adapter"
    end
  end

  describe "#transition_to" do
    # I'm generally not a fan of generating examples, but there are a great many permutations and writing them out
    # long form would be less understandable, IMHO. Please preserve the formatting for readability.

    [
      # Current            Target              Expected

      # Common transitions, automated action determination (no action specified in the target)
      [%i[state_a ask],    %i[state_b],        %i[state_b ask]],
      [%i[state_a listen], %i[state_b],        %i[state_b ask]],

      # Transition state_back to self, automated action determination (no action specified in the target)
      [%i[state_a listen], %i[state_a],        %i[state_a ask]],
      [%i[state_a ask],    %i[state_a],        %i[state_a listen]],

      # Explicit action (action is not automated)
      [%i[state_a ask],    %i[state_a ask],    %i[state_a ask]],
      [%i[state_a listen], %i[state_a listen], %i[state_a listen]],
      [%i[state_a listen], %i[state_b listen], %i[state_b listen]],
      [%i[state_a ask],    %i[state_b listen], %i[state_b listen]]
    ].each do |current, target, expected|
      it "transitions from #{current} to #{expected} when given #{target}" do
        state_data = Socrates::Core::StateData.new(state_id: current[0], state_action: current[1])
        state      = StateA.new(adapter: Socrates::Adapters::Memory.new, data: state_data)

        state.transition_to target[0], action: target[1]

        expect(state.next_state_id).to eq expected[0]
        expect(state.next_state_action).to eq expected[1]
      end
    end
  end

  describe "#repeat_action" do
    let(:state_data) { Socrates::Core::StateData.new(state_id: :state_a, state_action: :ask) }
    subject(:state) { StateA.new(adapter: Socrates::Adapters::Memory.new, data: state_data) }

    it "sets the next state and action to the current state and action (so that it runs again)" do
      state.repeat_action

      expect(state.next_state_id).to eq :state_a
      expect(state.next_state_action).to eq :ask
    end
  end

  describe "#end_conversation" do
    let(:data) { { name: "Fitzgibbons", age: 42 } }
    let(:state_data) { Socrates::Core::StateData.new(state_id: :state_a, state_action: :ask, data: data) }
    subject(:state) { StateA.new(adapter: Socrates::Adapters::Memory.new, data: state_data) }

    it "sets the next state and action to nil, to indicate the flow is over " do
      state.end_conversation

      expect(state.next_state_id).to eq described_class::END_OF_CONVERSATION
      expect(state.next_state_action).to eq described_class::END_OF_CONVERSATION
    end

    it "clears out the state data" do
      expect(data.has_key?(:name)).to be true
      expect(data.has_key?(:age)).to be true

      state.end_conversation

      expect(data.has_key?(:name)).to be false
      expect(data.has_key?(:age)).to be false
    end
  end
end
