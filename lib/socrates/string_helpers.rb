require "active_support/inflector"

module StringHelpers
  def self.underscore_to_classname(underscored_symbol)
    underscored_symbol.to_s.camelize
  end

  def self.classname_to_underscore(classname)
    classname.underscore
  end

  # Lifted from Rails' text helpers.
  def self.pluralize(count, singular, plural_arg = nil, plural: plural_arg)
    word =
      if count == 1 || count =~ /^1(\.0+)?$/
        singular
      else
        plural || singular.pluralize
      end

    "#{count || 0} #{word}"
  end
end
