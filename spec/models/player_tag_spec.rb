require 'rails_helper'

RSpec.describe PlayerTag, type: :model do
  subject { create(:player_tag) }

  it "Has valid factory" do
    expect(subject.id).not_to be_nil
  end
end
