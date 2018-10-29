# Some request helper methods.
module RequestHelpers
  extend ActiveSupport

  def assert_created
    expect(response.content_type).to eq('application/vnd.api+json')
    expect(response).to have_http_status :created
    body = response_body
    expect(body).to include(:data)
    expect(body[:data]).to include(:id, :attributes)
  end

  def assert_success
    expect(response).to have_http_status :success
  end

  def assert_unauthorized
    expect(response).to have_http_status :unauthorized
  end

  def assert_validation_errors
    expect(response).to have_http_status 422
  end

  def assert_has_attributes(attrs)
    body = response_body
    expect(body[:data][:attributes]).to include(attrs)
  end

  def response_body
    HashWithIndifferentAccess.new(JSON.parse(response.body)) || {}
  end
end

RSpec.configure do |config|
  config.include RequestHelpers
end
