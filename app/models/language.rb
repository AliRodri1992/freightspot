class Language < ApplicationRecord
  has_many :translates, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
end
