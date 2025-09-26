class SocialConnectionsController < ApplicationController
  before_action :authenticate_user!

  def disconnect
    profile = current_user.user_social_profiles.find_by(social_media_type: params[:provider])
    if profile&.destroy
      redirect_to account_path, notice: "#{params[:provider].titleize} account disconnected successfully."
    else
      redirect_to account_path, alert: "Failed to disconnect #{params[:provider].titleize} account."
    end
  end

  def refresh_locations
    twitter_profile = current_user.twitter_profile

    if twitter_profile
      if twitter_profile.location_data_stale?
        LocationScrapingJob.perform_later(twitter_profile.id)
        redirect_to account_path, notice: 'Location data refresh started. This may take a few minutes.'
      else
        redirect_to account_path, notice: 'Location data was recently updated. Please wait before refreshing again.'
      end
    else
      redirect_to account_path, alert: 'No Twitter profile found. Please connect to Twitter first.'
    end
  end

  def create_city_connections
    connections = current_user.create_social_connections_from_locations!

    if connections.any?
      redirect_to account_path, notice: "Created #{connections.size} new city connections from your Twitter network!"
    else
      redirect_to account_path, alert: 'No new city connections could be created. Try refreshing your location data first.'
    end
  end

  def scrape_profile
    twitter_url = params[:twitter_url]&.strip

    if twitter_url.blank?
      redirect_to account_path, alert: 'Please enter a Twitter profile URL.'
      return
    end

    # Extract username from URL
    username = extract_username_from_url(twitter_url)

    if username.blank?
      redirect_to account_path, alert: 'Invalid Twitter URL format. Please use format: https://twitter.com/username'
      return
    end

    begin
      service = ScrapeCreatorsService.new

      # Get follower locations directly without OAuth
      followers_locations = service.get_followers_locations(username, limit: 50)
      following_locations = service.get_following_locations(username, limit: 50)

      # Store the scraped data temporarily or create a profile record
      profile = current_user.user_social_profiles.find_or_create_by(
        social_media_type: 'twitter_manual'
      ) do |p|
        p.twitter_username = username
        p.social_media_user_id = username
      end

      profile.update!(
        followers_locations: followers_locations,
        following_locations: following_locations,
        last_scraped_at: Time.current,
        twitter_username: username
      )

      all_locations = (followers_locations + following_locations).flatten.uniq.compact

      if all_locations.any?
        # Create city records
        all_locations.each do |location|
          City.find_or_create_by(name: location.strip.titleize)
        end

        redirect_to account_path, notice: "Successfully scraped #{all_locations.size} locations from @#{username}!"
      else
        redirect_to account_path, alert: "No location data found for @#{username}. They may have no followers/following with location info."
      end

    rescue => e
      Rails.logger.error "Profile scraping error for #{username}: #{e.message}"
      redirect_to account_path, alert: 'Failed to scrape profile. Please check the username and try again.'
    end
  end

  private

  def extract_username_from_url(url)
    # Handle various Twitter URL formats
    if url.match?(/^@?\w+$/)
      # Just a username like "@username" or "username"
      return url.gsub(/^@/, '')
    end

    # Full URL formats
    uri = URI.parse(url) rescue nil
    return nil unless uri

    # Extract from path like /username or /username/
    if uri.path&.match(%r{^/(\w+)/?$})
      return $1
    end

    nil
  end
end 