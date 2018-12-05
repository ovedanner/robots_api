# JSON validator.
class JsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    message = (options[:message] || 'Invalid JSON')
    begin
      !value || JSON.parse(value)
    rescue
      record.errors[attribute] << message
    end
  end
end
