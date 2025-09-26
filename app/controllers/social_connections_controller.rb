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
end 