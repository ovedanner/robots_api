# Matches a request as a jsonapi error response, optionally with
# validation errors.
RSpec::Matchers.define :be_json_api_error_response do |attrs|
  match do |actual|
    parsed = HashWithIndifferentAccess.new(JSON.parse(actual))
    result = parsed.dig(:errors)&.is_a?(Array)
    if attrs
      attrs = [attrs] unless attrs.is_a?(Array)
      attrs.map! { |attr| "/data/attributes/#{attr}" }
      errors = parsed[:errors].map { |err| err.dig(:source, :pointer) }
      errors.uniq!

      result &&= (errors == attrs)
    end

    result
  end
end
