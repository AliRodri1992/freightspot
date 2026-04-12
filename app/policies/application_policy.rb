# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def method_missing(method_name, *arguments, &block)
    return super unless method_name.to_s.end_with?('?')

    action = "#{record.class.name.underscore.pluralize}.#{method_name.to_s.delete('?')}"
    user.can?(action)
  end

  def respond_to_missing?(method_name, include_private = false)
    return true if user.superadmin?
    return super unless method_name.to_s.end_with?('?')

    action = "#{record.class.name.underscore.pluralize}.#{method_name.to_s.delete('?')}"
    user.can?(action)
  end
end
