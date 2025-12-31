require 'rails_helper'

RSpec.describe NotificationRecipientsQuery do
  let(:season) { create(:season) }
  let(:player1) { create(:player, name: 'Player 1', confirmed_at: Time.now) }
  let(:player2) { create(:player, name: 'Player 2', confirmed_at: Time.now) }
  let(:player3) { create(:player, name: 'Player 3', confirmed_at: Time.now) }
  let(:match) { create(:match, season: season) }
  let(:notifier_class) { MatchUpdatedNotifier }

  before do
    create(:enrollment, season: season, player: player1)
    create(:enrollment, season: season, player: player2)
    create(:enrollment, season: season, player: player3)
    match.assignments << build(:assignment, match: match, player: player1, side: 1)
    match.assignments << build(:assignment, match: match, player: player2, side: 2)
    match.save!
  end

  describe '#call' do
    context 'when subject is a Match' do
      it 'includes assigned players' do
        result = described_class.call(match, notifier_class)
        expect(result).to include(player1, player2)
      end

      it 'includes players who commented' do
        create(:comment, commentable: match, player: player3)
        result = described_class.call(match, notifier_class)
        expect(result).to include(player3)
      end

      it 'excludes explicitly excluded players' do
        result = described_class.call(match, notifier_class, exclude: [player1.id])
        expect(result).to include(player2)
        expect(result).not_to include(player1)
      end

      it 'excludes players who already have a pending notification' do
        event = MatchUpdatedNotifier.create!(record: match)
        Noticed::Notification.create!(event: event, recipient: player1, type: "MatchUpdatedNotifier::Notification")
        
        result = described_class.call(match, notifier_class)
        expect(result).to include(player2)
        expect(result).not_to include(player1)
      end

      it 'only includes active players' do
        player2.update(anonymized_at: Time.now)
        result = described_class.call(match, notifier_class)
        expect(result).to include(player1)
        expect(result).not_to include(player2)
      end
    end

    context 'when subject is a Tournament' do
      let(:tournament) { create(:tournament, season: season) }
      let(:notifier_class) { NewCommentNotifier }

      it 'includes players who commented' do
        create(:comment, commentable: tournament, player: player3)
        result = described_class.call(tournament, notifier_class)
        expect(result).to include(player3)
      end

      it 'does not include players who did not comment' do
        result = described_class.call(tournament, notifier_class)
        expect(result).to be_empty
      end
    end
  end
end
