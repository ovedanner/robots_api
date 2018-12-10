# JSON validator.
class JsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    message = (options[:message] || 'Invalid JSON')
    begin
      !value || value.to_json
    rescue
      record.errors[attribute] << message
    end
  end
end
