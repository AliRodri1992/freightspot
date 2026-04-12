# frozen_string_literal: true
class RolePolicy < ApplicationPolicy
  def index?
    suoeradmin?
  end

  def edit?
    suoeradmin?
  end

  def toggle_permissions?
    suoeradmin?
  end
end
