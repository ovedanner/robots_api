# JSON validator.
class JsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    message = (options[:message] || 'Invalid JSON')
    if !value || value.is_a?(Array) || value.is_a?(Hash)
      true
    else
      record.errors[attribute] << message
    end
  end
end
