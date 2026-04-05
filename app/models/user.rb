class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :timeoutable, :session_limitable

  has_many :visits, class_name: 'Ahoy::Visit', dependent: :destroy
  has_many :events, class_name: 'Ahoy::Event', dependent: :destroy
  has_many :user_activities, dependent: :destroy
end
