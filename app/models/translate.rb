class Translate < ApplicationRecord
  belongs_to :language

  enum :status, { pending: 'pending', processed: 'processed' }

  validates :key, presence: true
  validates :key, uniqueness: { scope: :language_id }
end
