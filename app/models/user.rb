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

  # Get Twitter profile for this user
  def twitter_profile
    user_social_profiles.find_by(social_media_type: 'twitter')
  end

  # Get all locations from followers and following
  def discovered_locations
    return [] unless twitter_profile

    twitter_profile.all_locations
  end

  # Create social connections for discovered locations
  def create_social_connections_from_locations!
    locations = discovered_locations
    return [] if locations.empty?

    connections = []
    locations.each do |location_name|
      city = City.find_by(name: location_name.strip.titleize)
      next unless city

      connection = social_connections.find_or_create_by(city: city) do |conn|
        conn.platform = 'twitter'
        conn.connection_type = 'discovered'
        conn.metadata = { discovered_from: 'followers_following_locations' }
      end
      connections << connection if connection.persisted?
    end

    connections
  end

  # :nocov:
  def self.ransackable_attributes(*)
    ["id", "admin", "created_at", "updated_at", "email", "stripe_customer_id", "stripe_subscription_id", "paying_customer"]
  end

  def self.ransackable_associations(_auth_object)
    []
  end
  # :nocov:
end
