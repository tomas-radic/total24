require "rails_helper"

RSpec.describe "Percentage", type: :model do
  subject { Percentage.calculate(count, of:) }

  let(:of) { 1000 }

  context "250 of 1000" do
    let(:count) { 250 }

    it "Returns 25" do
      expect(subject).to eq(25)
    end
  end

  context "4 of 1000" do
    let(:count) { 4 }

    it "Returns 1" do
      expect(subject).to eq(1)
    end
  end

  context "990 of 1000" do
    let(:count) { 990 }

    it "Returns 99" do
      expect(subject).to eq(99)
    end
  end

  context "1300 of 1000" do
    let(:count) { 1300 }

    it "Returns 130" do
      expect(subject).to eq(130)
    end
  end
end
