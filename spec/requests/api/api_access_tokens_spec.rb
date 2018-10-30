require 'rails_helper'

RSpec.describe 'Api::AccessTokens', type: :request do
  let(:user) do
    FactoryBot.create(:user, email: 'guy@test.com', password: 'Safe1234')
  end

  describe 'POST api/access_tokens' do
    let(:invalid_credentials) do
      { email: 'guy@test.com', password: 'None3xist3nt'}
    end

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

  describe 'DELETE api/access_tokens/:id' do
    let(:access_token) { FactoryBot.create(:access_token, user: user) }

    context 'with valid credentials' do
      it 'deletes the access token' do
        delete "/api/access_tokens/#{access_token.id}",
               headers: auth_header(access_token.token)
        assert_success
      end
    end

    context 'with invalid credentials' do
      it 'raises unauthorized exception' do
        delete "/api/access_tokens/#{access_token.id}"
        assert_unauthorized
      end
    end
  end
end
