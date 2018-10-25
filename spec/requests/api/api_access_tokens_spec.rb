require 'rails_helper'

RSpec.describe 'Api::AccessTokens', type: :request do
  describe 'POST api/access_tokens' do
    let(:user) do
      FactoryBot.create(:user, email: 'guy@test.com', password: 'Safe1234')
    end

    let(:invalid_credentials) { { email: 'guy@test.com', password: 'None3xist3nt'} }

    context 'with valid credentials' do
      it 'returns an access key' do
        params = { email: user.email, password: user.password }
        post '/api/access_tokens', params: params
        assert_created
        assert_has_attributes(:token)


      end
    end

    context 'with invalid credentials' do
      it 'raises unauthorized exception' do
        post '/api/access_tokens', params: invalid_credentials
        assert_unauthorized
      end
    end
  end
end
