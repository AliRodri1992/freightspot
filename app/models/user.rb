class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable, :session_limitable

  belongs_to :role

  has_many :visits, class_name: 'Ahoy::Visit', dependent: :destroy
  has_many :events, class_name: 'Ahoy::Event', dependent: :destroy
  has_many :user_activities, dependent: :destroy

  def permissions_cache
    @permissions_cache ||= role.permissions.pluck(:name)
  end

  def can?(permission)
    permissions_cache.include?(permission.to_s)
  end

  def admin?
    %w[admin superadmin].include?(role.name)
  end

  def superadmin?
    role.name == 'superadmin'
  end

  def admin_or_superadmin?
    admin? || superadmin?
  end
end
