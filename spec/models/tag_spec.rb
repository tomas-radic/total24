require 'rails_helper'

RSpec.describe Tag, type: :model do
  subject { build(:tag) }

  it "Has valid factory" do
    expect(subject).to be_valid
  end
end
