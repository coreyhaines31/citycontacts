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
end 