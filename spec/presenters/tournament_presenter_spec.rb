require 'rails_helper'

RSpec.describe TournamentPresenter do
  let(:begin_date) { Date.new(2025, 12, 26) } # 2025-12-26 is Friday (pia)
  let(:end_date) { Date.new(2025, 12, 27) } # 2025-12-27 is Saturday (sob)
  let(:tournament) { build(:tournament, begin_date: begin_date, end_date: end_date) }
  let(:presenter) { described_class.new(tournament) }

  describe '#date' do
    context 'when both begin_date and end_date are present' do
      it 'returns a formatted date range' do
        # 26. dec is pia
        # 27. dec is sob
        expect(presenter.date).to eq('pia, 26. dec - sob, 27. dec')
      end
    end

    context 'when only begin_date is present' do
      let(:tournament) { build(:tournament, begin_date: begin_date, end_date: nil) }

      it 'returns only the begin_date' do
        expect(presenter.date).to eq('pia, 26. dec')
      end
    end

    context 'when begin_date is missing' do
      let(:tournament) { build(:tournament, begin_date: nil, end_date: end_date) }

      it 'returns an empty string' do
        expect(presenter.date).to eq('')
      end
    end

    context 'when both dates are missing' do
      let(:tournament) { build(:tournament, begin_date: nil, end_date: nil) }

      it 'returns an empty string' do
        expect(presenter.date).to eq('')
      end
    end
  end
end
