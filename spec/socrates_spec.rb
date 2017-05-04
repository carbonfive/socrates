require "spec_helper"

require "socrates/version"

RSpec.describe Socrates do
  it "has a version number" do
    expect(Socrates::VERSION).not_to be nil
  end
end
