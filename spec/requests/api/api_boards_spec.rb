require 'rails_helper'

RSpec.describe 'Api::Boards', type: :request do
  describe 'GET /api/boards/random' do
    context 'without valid credentials' do
      it 'succeeds' do
        get '/api/boards/random', headers: auth_header('bogustoken')
        assert_success
        assert_valid_board_data(response_body[:data][:attributes])
      end
    end
  end
end
