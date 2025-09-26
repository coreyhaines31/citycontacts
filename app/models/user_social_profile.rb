class UserSocialProfile < ApplicationRecord
  belongs_to :user

  validates :social_media_type, presence: true
  validates :access_token, presence: true
  validates :user_id, uniqueness: { scope: :social_media_type }

  # Store location arrays as JSON
  def followers_locations
    JSON.parse(read_attribute(:followers_locations) || '[]')
  rescue JSON::ParserError
    []
  end

  def followers_locations=(value)
    write_attribute(:followers_locations, value.to_json)
  end

  def following_locations
    JSON.parse(read_attribute(:following_locations) || '[]')
  rescue JSON::ParserError
    []
  end

  def following_locations=(value)
    write_attribute(:following_locations, value.to_json)
  end

  # Check if location data needs updating (older than 24 hours)
  def location_data_stale?
    last_scraped_at.nil? || last_scraped_at < 24.hours.ago
  end

  # Get unique locations from both followers and following
  def all_locations
    (followers_locations + following_locations).flatten.uniq.compact
  end

  # Update location data using ScrapeCreators API
  def update_location_data!
    return unless social_media_type == 'twitter' && twitter_username.present?

    service = ScrapeCreatorsService.new

    # Get followers' locations
    followers_locs = service.get_followers_locations(twitter_username, limit: 100)

    # Get following users' locations
    following_locs = service.get_following_locations(twitter_username, limit: 100)

    update!(
      followers_locations: followers_locs,
      following_locations: following_locs,
      last_scraped_at: Time.current
    )

    all_locations
  rescue => e
    Rails.logger.error "Failed to update location data for user #{user_id}: #{e.message}"
    false
  end
end
