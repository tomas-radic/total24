require 'rails_helper'

RSpec.describe PlayerPresenter do
  let(:player) { create(:player, name: 'John Doe') }

  describe '#name' do
    context 'without privacy' do
      it 'returns the full name' do
        presenter = PlayerPresenter.new(player, privacy: false)
        expect(presenter.name).to eq('John Doe')
      end

      it 'defaults privacy to false' do
        presenter = PlayerPresenter.new(player)
        expect(presenter.name).to eq('John Doe')
      end
    end

    context 'with privacy' do
      it 'returns the first name and initials of other parts' do
        presenter = PlayerPresenter.new(player, privacy: true)
        expect(presenter.name).to eq('John D.')
      end

      it 'handles names with multiple parts' do
        player.update!(name: 'John Quincy Adams')
        presenter = PlayerPresenter.new(player, privacy: true)
        expect(presenter.name).to eq('John Q. A.')
      end

      it 'handles single part names' do
        player.update!(name: 'John')
        presenter = PlayerPresenter.new(player, privacy: true)
        expect(presenter.name).to eq('John')
      end
    end
  end
end
