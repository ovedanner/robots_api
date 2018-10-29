require 'rails_helper'

RSpec.describe 'Api::Users', type: :request do
  describe 'POST /api_users' do
    context 'with valid request data' do
      let(:valid_data) do
        {
          data: {
            type: 'users',
            attributes: {
              email: 'new_user@test.com',
              firstname: 'Guy',
              password: 'Test1234',
              password_confirmation: 'Test1234'
            }
          }
        }
      end

      it 'will succeed' do
        post '/api/users', params: valid_data
        assert_created
        expect(response.body).to be_json_api_success_response('users')
      end
    end

    context 'with missing request data' do
      let(:invalid_data) do
        {
          data: {
            type: 'users',
            attributes: {
              password: 'Test1234',
              password_confirmation: 'Test1234'
            }
          }
        }
      end

      it 'will fail with validation errors' do
        post '/api/users', params: invalid_data
        assert_validation_errors
        expect(response.body).to be_json_api_error_response(%w[email firstname])
      end
    end
  end
end
