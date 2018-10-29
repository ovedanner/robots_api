# Matches a request as a successful jsonapi response.
RSpec::Matchers.define :be_json_api_success_response do |expected|
  match do |actual|
    parsed = HashWithIndifferentAccess.new(JSON.parse(actual))
    parsed.dig(:data, :type) == expected &&
      parsed.dig(:data, :attributes).is_a?(Hash)
  end
end
