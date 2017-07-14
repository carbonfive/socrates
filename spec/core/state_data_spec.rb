require "spec_helper"

require "socrates/core/state_data"

TestWidget = Struct.new(:id, :name, :active)

RSpec.describe Socrates::Core::StateData do
  before do
    Socrates.configure do |config|
      config.expired_timeout = 120
    end
  end

  subject(:data) { described_class.new(data: { a: 100, b: { b1: "abc", b2: "xyz" } }) }

  describe "#finished?" do
    subject { described_class.new(state_id: state_id).finished? }

    context "when the state_id is nil" do
      let(:state_id) { nil }

      it { is_expected.to be true }
    end

    context "when the state_id is END_OF_CONVERSATION" do
      let(:state_id) { described_class::END_OF_CONVERSATION }

      it { is_expected.to be true }
    end

    context "when the state_id is anything else" do
      let(:state_id) { :something_else }

      it { is_expected.to be false }
    end
  end

  describe "#expired?" do
    subject do
      described_class.new.tap { |state_data| state_data.last_interaction_timestamp = last_interaction }.expired?
    end

    context "when there has been no last interaction" do
      let(:last_interaction) { nil }

      it { is_expected.to be false } # TODO: Really?
    end

    context "when the last interaction was a while ago" do
      let(:last_interaction) { 121.seconds.ago }

      it { is_expected.to be true }
    end

    context "when the last interaction is within the threshold" do
      let(:last_interaction) { 119.seconds.ago }

      it { is_expected.to be false }
    end
  end

  describe "#keys" do
    it "returns an array of keys" do
      expect(data.keys).to contain_exactly(:a, :b)
    end
  end

  describe "#has_key?" do
    it "returns whether or not there's a value with the key" do
      expect(data.has_key?(:nope)).to be false
      expect(data.has_key?(:a)).to be true
    end
  end

  describe "#has_temporary_key?" do
    it "returns whether or not there's a temporary value with the key" do
      data.set_temporary(:temp, "tick-tock")
      expect(data.has_temporary_key?(:temp)).to be true
    end

    it "returns false if passed a regular key" do
      expect(data.has_temporary_key?(:a)).to be false
    end
  end

  describe "#get" do
    it "fetches values with symbol keys" do
      expect(data.get(:a)).to eq(100)
      expect(data.get(:b)).to eq(b1: "abc", b2: "xyz")
    end

    it "clears the value when clear: true is passed" do
      expect(data.get(:a, clear: true)).to eq(100)
      expect(data.has_key?(:a)).to be false
    end
  end

  describe "#set" do
    it "sets new values which are then fetchable" do
      expect(data.has_key?(:name)).to be false
      data.set(:name, "Christian")
      expect(data.get(:name)).to eq("Christian")
    end
  end

  describe "#set_temporary" do
    it "stores the value and clears it once it has been fetched" do
      expect(data.has_key?(:name)).to be false

      data.set_temporary(:name, "Christian")
      expect(data.get(:name)).to eq("Christian")

      expect(data.has_key?(:name)).to be false
      expect(data.get(:name)).to be nil
    end

    it "raises an exception if a non-temporary value has already been set with this key" do
      expect { data.set_temporary(:a, "Christian") }.to raise_error ArgumentError
    end
  end

  describe "#merge" do
    it "merges the specified hash into this state data" do
      data.merge(c: 500)
      expect(data.has_key?(:c)).to be true
      expect(data.get(:c)).to eq 500
    end

    it "replaces old values with new ones" do
      data.merge(a: 500)
      expect(data.has_key?(:a)).to be true
      expect(data.get(:a)).to eq 500
    end
  end

  describe "#clear" do
    it "removes the value associated with the key" do
      expect(data.has_key?(:a)).to be true
      data.clear(:a)
      expect(data.has_key?(:a)).to be false
      expect(data.get(:a)).to be nil
    end
  end

  describe "serialization" do
    it "serializes to yaml and back" do
      string   = data.serialize
      new_data = described_class.deserialize(string)

      expect(new_data.keys).to contain_exactly(*data.keys)

      data.keys.each do |key|
        expect(data.get(key)).to eq new_data.get(key)
      end
    end

    it "preserves temporary keys and values through serialization" do
      data.state_id = :additional_info
      data.set_temporary(:temp, "time is slipping")
      data.set(:widgets, [
        TestWidget.new(10, "W 1", true),
        TestWidget.new(15, "W 2", true),
        TestWidget.new(20, "W 3", false)
      ])

      string   = data.serialize
      new_data = described_class.deserialize(string)

      expect(new_data.state_id).to eq :additional_info
      expect(new_data.has_temporary_key?(:temp)).to be true
      expect(new_data.get(:temp)).to eq "time is slipping"
      expect(new_data.has_temporary_key?(:temp)).to be false

      expect(new_data.has_key?(:widgets)).to be true

      widgets = new_data.get(:widgets)

      expect(widgets.count).to eq 3
      widgets.each do |widget|
        expect(widget).to be_a_kind_of(TestWidget)
      end

      expect(widgets[0].id).to eq 10
      expect(widgets[0].name).to eq "W 1"
      expect(widgets[0].active).to eq true
    end
  end
end
