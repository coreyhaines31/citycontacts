require 'oauth2'
require 'securerandom'
require 'openssl'
require 'digest'

class TwitterAuthController < ApplicationController
  before_action :authenticate_user!

  TWITTER_SCOPES = [
    'tweet.read',
    'users.read',
    'offline.access'
  ].join(' ').freeze

  def request_authorization
    Rails.logger.info "Starting Twitter OAuth request"
    session[:twitter_state] = SecureRandom.hex(16)
    session[:code_verifier] = code_verifier = SecureRandom.hex(32)
    
    code_challenge = Base64.urlsafe_encode64(
      Digest::SHA256.digest(code_verifier),
      padding: false
    )

    auth_url = client.auth_code.authorize_url(
      redirect_uri: callback_url,
      scope: TWITTER_SCOPES,
      state: session[:twitter_state],
      code_challenge: code_challenge,
      code_challenge_method: 'S256',
      response_type: 'code'
    )

    Rails.logger.info "Twitter credentials: #{Rails.application.credentials.twitter.inspect}"
    Rails.logger.info "Callback URL: #{callback_url}"
    Rails.logger.info "Scopes: #{TWITTER_SCOPES}"
    Rails.logger.info "Redirecting to Twitter: #{auth_url}"
    redirect_to auth_url, allow_other_host: true
  end

  def callback
    Rails.logger.info "Twitter callback received"
    Rails.logger.info "Params: #{params.inspect}"
    Rails.logger.info "Session state: #{session[:twitter_state]}"
    Rails.logger.info "Session code_verifier: #{session[:code_verifier].present?}"

    if params[:error].present?
      error_message = "Twitter authentication failed: #{params[:error]}"
      Rails.logger.error error_message
      Rails.logger.error "Error description: #{params[:error_description]}"
      redirect_to account_path, alert: error_message
      return
    end

    if invalid_state?
      error_message = 'Invalid state parameter. Please try again.'
      Rails.logger.error error_message
      Rails.logger.error "Expected state: #{session[:twitter_state]}"
      Rails.logger.error "Received state: #{params[:state]}"
      redirect_to account_path, alert: error_message
      return
    end

    begin
      Rails.logger.info "Exchanging code for token"
      token = client.auth_code.get_token(
        params[:code],
        redirect_uri: callback_url,
        code_verifier: session.delete(:code_verifier)
      )
      Rails.logger.info "Token received: #{token.token.present?}"

      Rails.logger.info "Fetching user data"
      user_data = token.get('https://api.twitter.com/2/users/me').parsed
      Rails.logger.info "User data received: #{user_data.inspect}"
      
      if user_data['data'].present?
        save_twitter_profile(token, user_data['data'])
        redirect_to account_path, notice: 'Successfully connected to Twitter!'
      else
        error_message = 'Failed to fetch Twitter profile data.'
        Rails.logger.error error_message
        Rails.logger.error "User data response: #{user_data.inspect}"
        redirect_to account_path, alert: error_message
      end
    rescue OAuth2::Error => e
      Rails.logger.error "Twitter OAuth Error: #{e.message}"
      Rails.logger.error "Response body: #{e.response&.body}"
      redirect_to account_path, alert: 'Failed to authenticate with Twitter. Please try again.'
    rescue StandardError => e
      Rails.logger.error "Unexpected error in Twitter callback: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to account_path, alert: 'An unexpected error occurred. Please try again.'
    end
  end

  private

  def client
    @client ||= OAuth2::Client.new(
      Rails.application.credentials.twitter.client_id,
      Rails.application.credentials.twitter.client_secret,
      site: 'https://api.twitter.com',
      authorize_url: 'https://twitter.com/i/oauth2/authorize',
      token_url: 'https://api.twitter.com/2/oauth2/token'
    )
  end

  def callback_url
    twitter_callback_url
  end

  def invalid_state?
    params[:state].blank? || params[:state] != session.delete(:twitter_state)
  end

  def save_twitter_profile(token, user_data)
    Rails.logger.info "Saving Twitter profile for user #{user_data['id']}"
    profile = current_user.user_social_profiles.find_or_initialize_by(
      social_media_type: 'twitter'
    )

    profile.update!(
      social_media_user_id: user_data['id'],
      access_token: token.token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at ? Time.at(token.expires_at) : nil
    )
    Rails.logger.info "Twitter profile saved successfully"
  end
end 