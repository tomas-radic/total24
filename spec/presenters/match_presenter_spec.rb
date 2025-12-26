require 'rails_helper'

RSpec.describe MatchPresenter do
  let(:player1) { create(:player, name: 'John Doe') }
  let(:player2) { create(:player, name: 'Jane Smith') }
  let(:match) { create(:match, :reviewed, winner_side: 1) }

  before do
    create(:assignment, match: match, player: player1, side: 1)
    create(:assignment, match: match, player: player2, side: 2)
    match.reload
  end

  describe '#side_names' do
    let(:player3) { create(:player, name: 'Bob Brown') }
    let(:player4) { create(:player, name: 'Alice White') }

    context 'single match' do
      it 'returns side 1 name' do
        expect(described_class.new(match).side_names(1)).to eq('John Doe')
      end

      it 'returns side 2 name' do
        expect(described_class.new(match).side_names(2)).to eq('Jane Smith')
      end

      it 'respects privacy' do
        expect(described_class.new(match, privacy: true).side_names(1)).to eq('John D.')
      end
    end

    context 'double match' do
      it 'returns side 1 names joined by comma' do
        season = Season.new(name: 'Season 2025', performance_player_tag_label: 'P', performance_play_off_size: 8, play_off_min_matches_count: 5, regular_a_play_off_size: 8, regular_b_play_off_size: 8, ended_at: Time.now)
        season.save!
        double_match = build(:match, kind: :double, competitable: season)
        create(:enrollment, season: season, player: player1)
        create(:enrollment, season: season, player: player2)
        create(:enrollment, season: season, player: player3)
        create(:enrollment, season: season, player: player4)
        double_match.assignments << build(:assignment, match: double_match, player: player1, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player3, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player2, side: 2)
        double_match.assignments << build(:assignment, match: double_match, player: player4, side: 2)
        double_match.save!

        expect(described_class.new(double_match).side_names(1)).to eq('John Doe, Bob Brown')
      end

      it 'returns side 2 names joined by comma' do
        season = Season.new(name: 'Season 2025-2', performance_player_tag_label: 'P', performance_play_off_size: 8, play_off_min_matches_count: 5, regular_a_play_off_size: 8, regular_b_play_off_size: 8, ended_at: Time.now)
        season.save!
        double_match = build(:match, kind: :double, competitable: season)
        create(:enrollment, season: season, player: player1)
        create(:enrollment, season: season, player: player2)
        create(:enrollment, season: season, player: player3)
        create(:enrollment, season: season, player: player4)
        double_match.assignments << build(:assignment, match: double_match, player: player1, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player3, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player2, side: 2)
        double_match.assignments << build(:assignment, match: double_match, player: player4, side: 2)
        double_match.save!

        expect(described_class.new(double_match).side_names(2)).to eq('Jane Smith, Alice White')
      end

      it 'respects privacy' do
        season = Season.new(name: 'Season 2025-3', performance_player_tag_label: 'P', performance_play_off_size: 8, play_off_min_matches_count: 5, regular_a_play_off_size: 8, regular_b_play_off_size: 8, ended_at: Time.now)
        season.save!
        double_match = build(:match, kind: :double, competitable: season)
        create(:enrollment, season: season, player: player1)
        create(:enrollment, season: season, player: player2)
        create(:enrollment, season: season, player: player3)
        create(:enrollment, season: season, player: player4)
        double_match.assignments << build(:assignment, match: double_match, player: player1, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player3, side: 1)
        double_match.assignments << build(:assignment, match: double_match, player: player2, side: 2)
        double_match.assignments << build(:assignment, match: double_match, player: player4, side: 2)
        double_match.save!

        expect(described_class.new(double_match, privacy: true).side_names(1)).to eq('John D., Bob B.')
      end
    end
  end

  describe '#looser_names' do
    context 'without privacy' do
      subject { described_class.new(match, privacy: false).looser_names }

      it 'returns the name of the looser' do
        expect(subject).to eq('Jane Smith')
      end
    end

    context 'with privacy' do
      subject { described_class.new(match, privacy: true).looser_names }

      it 'returns the privacy name of the looser' do
        expect(subject).to eq('Jane S.')
      end
    end

    context 'when match is not reviewed' do
      let(:match) { create(:match, :finished, reviewed_at: nil) }

      it 'returns nil' do
        expect(described_class.new(match).looser_names).to be_nil
      end
    end

    context 'when side 2 is winner' do
      let(:match) { create(:match, :reviewed, winner_side: 2) }

      it 'returns the name of side 1' do
        expect(described_class.new(match).looser_names).to eq('John Doe')
      end
    end
  end
  describe '#result_from_side' do
    context 'when match is finished' do
      let(:match) do
        create(:match, :finished,
               set1_side1_score: 6, set1_side2_score: 4,
               set2_side1_score: 3, set2_side2_score: 6,
               set3_side1_score: 7, set3_side2_score: 5)
      end

      it 'returns the formatted result from side 1' do
        expect(described_class.new(match).result_from_side(1)).to eq('6:4, 3:6, 7:5')
      end

      it 'returns the formatted result from side 2' do
        expect(described_class.new(match).result_from_side(2)).to eq('4:6, 6:3, 5:7')
      end

      it 'defaults to side 1' do
        expect(described_class.new(match).result_from_side).to eq('6:4, 3:6, 7:5')
      end
    end

    context 'when match has only one set' do
      let(:match) do
        create(:match, :finished,
               set1_side1_score: 6, set1_side2_score: 0,
               set2_side1_score: nil, set2_side2_score: nil)
      end

      it 'returns only one set result' do
        expect(described_class.new(match).result_from_side(1)).to eq('6:0')
      end
    end

    context 'when match is retired' do
      let(:match) { create(:match, :finished, set1_side1_score: 3, set1_side2_score: 0) }

      before do
        match.assignments.find_by(side: 2).update(is_retired: true)
      end

      it 'includes (skreč) in the result' do
        expect(described_class.new(match).result_from_side(1)).to eq('3:0, (skreč)')
      end
    end

    context 'when match is not finished' do
      let(:match) { create(:match, :requested) }

      it 'returns nil' do
        expect(described_class.new(match).result_from_side).to be_nil
      end
    end
  end

  describe '#label' do
    it 'returns side 1 vs. side 2' do
      expect(described_class.new(match).label).to eq('John Doe vs. Jane Smith')
    end

    it 'respects privacy' do
      expect(described_class.new(match, privacy: true).label).to eq('John D. vs. Jane S.')
    end
  end

  describe '#predictions' do
    let(:prediction1) { create(:prediction, match: match, side: 1) }
    let(:prediction2) { create(:prediction, match: match, side: 2) }
    let(:prediction3) { create(:prediction, match: match, side: 1) }

    context 'when there are predictions' do
      before do
        prediction1
        prediction2
        prediction3
      end

      it 'returns the formatted predictions count' do
        expect(described_class.new(match).predictions).to eq('2/1')
      end
    end

    context 'when there are no predictions' do
      it 'returns an empty string' do
        expect(described_class.new(match).predictions).to eq('')
      end
    end
  end
end
