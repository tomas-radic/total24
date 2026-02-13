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
          player.update!(cant_play_since: Time.current)
        end

        it 'clears cant_play_since' do
          expect { subject }.to change { player.reload.cant_play_since }.to(nil)
        end
      end
    end

    context 'when setting to not open' do
      subject { service.set_open_to_play(player, false) }

      before do
        player.update!(open_to_play_since: Time.current)
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
          player.update!(open_to_play_since: Time.current)
        end

        it 'clears open_to_play_since' do
          expect { subject }.to change { player.reload.open_to_play_since }.to(nil)
        end
      end
    end

    context 'when setting to can play' do
      subject { service.set_cant_play(player, true) }

      before do
        player.update!(cant_play_since: Time.current)
      end

      it 'clears cant_play_since' do
        expect { subject }.to change { player.reload.cant_play_since }.to(nil)
      end
    end
  end

end
