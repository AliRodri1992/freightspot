class Translate < ApplicationRecord
  belongs_to :language

  enum :status, { pending: 0, completed: 1, failed: 2 }

  validates :key, presence: true
end
