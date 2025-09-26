class User < ApplicationRecord
  include Signupable
  include Onboardable
  include Billable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :social_connections
  has_many :cities, through: :social_connections
  has_many :user_social_profiles

  scope :subscribed, -> { where.not(stripe_subscription_id: [nil, '']) }

  # :nocov:
  def self.ransackable_attributes(*)
    ["id", "admin", "created_at", "updated_at", "email", "stripe_customer_id", "stripe_subscription_id", "paying_customer"]
  end

  def self.ransackable_associations(_auth_object)
    []
  end
  # :nocov:
end
