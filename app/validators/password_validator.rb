# Password validator for both length and characters.
class PasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless value && value.length >= 8 && value =~ /[A-Z]/ && value =~ /[0-9]/
      record.errors[attribute] << (options[:message] ||
        <<~HEREDOC
          Password needs to be at least 8 characters long and contain an uppercase character and a number
        HEREDOC
                                  )
    end
  end
end
