class Role < ApplicationRecord
  has_many :users, dependent: :destroy

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  validates :name, presence: true, uniqueness: true
end
