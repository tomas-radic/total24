require 'rails_helper'

RSpec.describe Tournament, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      tournament = build(:tournament)
      expect(tournament).to be_valid
    end

    it 'is valid when end_date is equal to begin_date' do
      tournament = build(:tournament, begin_date: Date.today, end_date: Date.today)
      expect(tournament).to be_valid
    end

    it 'is valid when end_date is after begin_date' do
      tournament = build(:tournament, begin_date: Date.today, end_date: Date.tomorrow)
      expect(tournament).to be_valid
    end

    it 'is invalid when end_date is before begin_date' do
      tournament = build(:tournament, begin_date: Date.today, end_date: Date.yesterday)
      expect(tournament).not_to be_valid
      expect(tournament.errors[:end_date]).to be_present
    end
  end
end
