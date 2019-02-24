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

  def assert_not_found
    expect(response).to have_http_status :not_found
  end

  def assert_validation_errors
    expect(response).to have_http_status 422
  end

  def assert_has_attributes(attrs)
    body = response_body
    expect(body[:data][:attributes]).to include(attrs)
  end

  def assert_returned_nr_records(nr, type)
    body = response_body
    records = body[:data]
    expect(records.length).to eq(nr)
    records.each do |record|
      expect(record[:type]).to eq(type)
    end
  end

  def assert_each_has_attributes(map)
    response_body[:data].each do |record|
      actual_values = record[:attributes]
      expected_values = map[record[:id].to_i]
      expected_values.keys.each do |attr|
        expect(actual_values[attr.to_s]).to eq(expected_values[attr])
      end
    end
  end

  def response_body
    HashWithIndifferentAccess.new(JSON.parse(response.body)) || {}
  end

  def auth_header(token)
    {
      'Authorization': "Token token=#{token}"
    }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers
end
