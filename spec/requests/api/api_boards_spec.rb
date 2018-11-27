require 'rails_helper'

RSpec.describe 'Api::Boards', type: :request do
  describe 'GET /api/boards/random' do
    context 'without valid credentials' do
      it 'succeeds' do
        get '/api/boards/random', headers: auth_header('bogustoken')
        assert_success
      end
    end
  end
end
