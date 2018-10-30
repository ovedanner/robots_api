require 'rails_helper'

RSpec.describe User, type: :model do
  describe '#email' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to allow_value('someone@test.com').for(:email) }

    it { is_expected.not_to allow_value('noatsign.com').for(:email) }
  end

  describe '#room_user' do
    it { is_expected.to have_many(:room_user) }
  end

  describe '#password' do
    it { is_expected.to have_secure_password }
    it { is_expected.to allow_value('Ddfdav499X!*fd%').for(:password) }

    it { is_expected.not_to allow_value('Ta1234').for(:password) }
    it { is_expected.not_to allow_value('test1234').for(:password) }
    it { is_expected.not_to allow_value('TestTest').for(:password) }
  end
end
