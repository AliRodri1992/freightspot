class UserActivity < ApplicationRecord
  belongs_to :user
  belongs_to :trackable, polymorphic: true, optional: true

  validates :action, presence: true
  validates :ip_address, presence: true

  def location_summary
    [city, region, country].compact.join(', ').presence || 'Ubicación desconocida'
  end
end
