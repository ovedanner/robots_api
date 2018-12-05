require 'rails_helper'

RSpec.describe AccessToken, type: :model do
  describe '#user' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to belong_to(:user) }
  end

  describe '.with_unexpired_token' do
    let(:user) { FactoryBot.create(:user) }

    context 'when token is not expired' do
      let(:valid_token) do
        FactoryBot.create(
          :access_token,
          user: user,
          token: AccessToken.generate_unique_secure_token,
          expires_at: 1.day.from_now)
      end
      it 'returns the token' do
        t = AccessToken.with_unexpired_token(valid_token.token)
        expect(t).to be_instance_of(AccessToken)
        expect(t.token).to eq(valid_token.token)
      end
    end

    context 'when token is expired' do
      let(:expired_token) do
        FactoryBot.create(
          :access_token,
          user: user,
          token: AccessToken.generate_unique_secure_token,
          expires_at: 12.hours.ago)
      end
      it 'does not return the token' do
        t = AccessToken.with_unexpired_token(expired_token.token)
        expect(t).to be_falsey
      end
    end
  end
end
