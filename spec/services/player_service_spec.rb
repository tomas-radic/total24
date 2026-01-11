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

  describe '#toggle_season_enrollment' do
    subject { service.toggle_season_enrollment(player, season) }

    context 'when enrollment does not exist' do
      it 'creates a new enrollment' do
        expect { subject }.to change { Enrollment.count }.by(1)
      end

      it 'returns success with the new enrollment' do
        expect(subject.success?).to be true
        expect(subject.value).to eq(Enrollment.order(:created_at).last)
      end

      it 'sets default values' do
        subject

        enrollment = player.enrollments.find_by(season:)
        expect(enrollment.canceled_at).to be_nil
        expect(enrollment.rules_accepted_at).not_to be_nil
        expect(enrollment.fee_amount_paid).to eq(0)
      end
    end

    context 'when enrollment exists' do
      let!(:enrollment) { create(:enrollment, player: player, season: season) }

      context 'when it is not canceled' do
        before do
          enrollment.update!(canceled_at: nil)
        end

        it 'sets canceled_at to current time' do
          expect { subject }.to change { enrollment.reload.canceled_at }.from(nil)
        end

        it 'returns success with the enrollment' do
          expect(subject.success?).to be true
          expect(subject.value).to eq(enrollment)
        end
      end

      context 'when it is canceled' do
        subject { service.toggle_season_enrollment(player, season) }

        before do
          enrollment.update!(canceled_at: Time.current)
        end

        it 'sets canceled_at to nil' do
          expect { subject }.to change { enrollment.reload.canceled_at }.to(nil)
        end

        it 'returns success with the enrollment' do
          expect(subject.success?).to be true
          expect(subject.value).to eq(enrollment)
        end
      end
    end
  end
end
