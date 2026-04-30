require 'rails_helper'

RSpec.describe Matches::ScoreValidator do
  describe '.call' do
    subject { described_class.call(score) }

    context 'valid 2-set matches' do
      let(:valid_scores) { %w[6060 6464 7560 6075 7676 0606] }
      it 'returns true' do
        valid_scores.each do |s|
          expect(described_class.call(s)).to be(true), "Expected #{s} to be valid"
        end
      end
    end

    context 'valid 3-set matches (regular 3rd set)' do
      let(:valid_scores) { %w[600660 644675 644657 466406] }
      it 'returns true' do
        valid_scores.each do |s|
          expect(described_class.call(s)).to be(true), "Expected #{s} to be valid"
        end
      end
    end

    context 'valid 3-set matches (short 3rd set)' do
      let(:valid_scores) { %w[600630 644631 466423 600603] }
      it 'returns true' do
        valid_scores.each do |s|
          expect(described_class.call(s)).to be(true), "Expected #{s} to be valid"
        end
      end
    end

    context 'invalid scores' do
      it 'returns false for wrong length' do
        expect(described_class.call('60')).to be(false)
        expect(described_class.call('60606')).to be(false)
        expect(described_class.call('60606060')).to be(false)
      end

      it 'returns false for supertiebreaks' do
        expect(described_class.call('1060')).to be(false)
        expect(described_class.call('6001')).to be(false)
      end

      it 'returns false for invalid set scores' do
        expect(described_class.call('5560')).to be(false)
        expect(described_class.call('8660')).to be(false)
        expect(described_class.call('6074')).to be(false)
      end

      it 'returns false if match not finished (no one won 2 sets)' do
        expect(described_class.call('6006')).to be(false)
      end

      it 'returns false if 3rd set played but someone already won 2 sets' do
        expect(described_class.call('606060')).to be(false)
      end

      it 'returns false for invalid 3rd set scores' do
        expect(described_class.call('600640')).to be(false)
        expect(described_class.call('600650')).to be(false)
      end
    end
  end
end
