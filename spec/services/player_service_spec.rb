require 'rails_helper'

RSpec.describe PlayerService do
  subject { service }

  let!(:service) { PlayerService.new }
  let!(:player) { create(:player) }
  let!(:season) { create(:season) }

  describe '#set_open_to_play' do
    context 'when setting to open' do
      subject { service.set_open_to_play(player, true) }

      it 'sets open_to_play_since to the current time' do
        expect { subject }.to change { player.reload.open_to_play_since }.from(nil)
      end

      context 'when player has cant_play_since set' do
        subject { service.set_open_to_play(player, true) }

        before do
          player.update(cant_play_since: Time.current)
        end

        it 'clears cant_play_since' do
          expect { subject }.to change { player.reload.cant_play_since }.to(nil)
        end
      end
    end

    context 'when setting to not open' do
      subject { service.set_open_to_play(player, false) }

      before do
        player.update(open_to_play_since: Time.current)
      end

      it 'clears open_to_play_since' do
        expect { subject }.to change { player.reload.open_to_play_since }.to(nil)
      end
    end
  end

  describe '#set_cant_play' do
    context 'when setting to cant play' do
      subject { service.set_cant_play(player, false) }

      it 'sets cant_play_since to the current time' do
        expect { subject }.to change { player.reload.cant_play_since }.from(nil)
      end

      context 'when player has open_to_play_since set' do
        subject { service.set_cant_play(player, false) }

        before do
          player.update(open_to_play_since: Time.current)
        end

        it 'clears open_to_play_since' do
          expect { subject }.to change { player.reload.open_to_play_since }.to(nil)
        end
      end
    end

    context 'when setting to can play' do
      subject { service.set_cant_play(player, true) }

      before do
        player.update(cant_play_since: Time.current)
      end

      it 'clears cant_play_since' do
        expect { subject }.to change { player.reload.cant_play_since }.to(nil)
      end
    end
  end

  describe '#get_players_open_to_play' do
    subject { service.get_players_open_to_play(season) }

    let!(:open_players) do
      players = create_list(:player, 3)
      players.each_with_index do |p, i|
        p.update(open_to_play_since: (i + 1).days.ago)
        create(:enrollment, season: season, player: p)
      end
      players
    end

    let!(:closed_players) do
      players = create_list(:player, 2, open_to_play_since: nil)
      players.each do |p|
        create(:enrollment, season: season, player: p)
      end
      players
    end

    it 'returns only players who are open to play' do
      expect(subject.count).to eq(3)
      expect(subject.pluck(:id)).to match_array(open_players.pluck(:id))
    end

    it 'orders players by open_to_play_since desc' do
      expect(subject.first.open_to_play_since).to be > subject.last.open_to_play_since
    end
  end
end
