class ScrapeCreatorsService
  include HTTParty

  base_uri 'https://api.scrapecreators.com/v1'

  def initialize
    @api_key = Rails.application.credentials.scrape_creators&.api_key
    raise 'ScrapeCreators API key not configured' unless @api_key
  end

  # Get Twitter user profile data including location
  def get_twitter_profile(username_or_url)
    response = self.class.get('/twitter/profile', {
      headers: headers,
      query: { handle: username_or_url }
    })

    handle_response(response)
  end

  # Get Twitter user's tweets to analyze mention patterns for location clues
  def get_twitter_tweets(username_or_url, limit: 100)
    response = self.class.get('/twitter/user-tweets', {
      headers: headers,
      query: {
        handle: username_or_url,
        limit: limit
      }
    })

    handle_response(response)
  end

  # Note: ScrapeCreators doesn't have followers/following endpoints
  # These methods are placeholders for the existing interface
  def get_twitter_followers(username_or_url, limit: 100)
    # Fallback: get profile data instead
    get_twitter_profile(username_or_url)
  end

  def get_twitter_following(username_or_url, limit: 100)
    # Fallback: get profile data instead
    get_twitter_profile(username_or_url)
  end

  # Extract location data from followers/following
  def extract_locations_from_users(users_data)
    return [] unless users_data.is_a?(Array)

    locations = []
    users_data.each do |user|
      location = extract_location_from_user(user)
      locations << location if location.present?
    end

    locations.uniq
  end

  # Get user's location from their profile (since followers/following not available)
  def get_followers_locations(username_or_url, limit: 100)
    profile_data = get_twitter_profile(username_or_url)
    return [] unless profile_data.success?

    # Extract location from the user's own profile
    location = extract_location_from_user(profile_data.data)
    location ? [location] : []
  end

  # Get user's location from their profile (since followers/following not available)
  def get_following_locations(username_or_url, limit: 100)
    profile_data = get_twitter_profile(username_or_url)
    return [] unless profile_data.success?

    # Extract location from the user's own profile
    location = extract_location_from_user(profile_data.data)
    location ? [location] : []
  end

  # Enhanced method to get location from profile and tweets
  def get_user_location_comprehensive(username_or_url)
    locations = []

    # Get location from profile
    profile_data = get_twitter_profile(username_or_url)
    if profile_data.success?
      profile_location = extract_location_from_user(profile_data.data)
      locations << profile_location if profile_location
    end

    # Get location clues from recent tweets
    tweets_data = get_twitter_tweets(username_or_url, limit: 20)
    if tweets_data.success? && tweets_data.data.is_a?(Array)
      tweet_locations = extract_locations_from_tweets(tweets_data.data)
      locations.concat(tweet_locations)
    end

    locations.uniq.compact
  end

  private

  def headers
    {
      'x-api-key' => @api_key,
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
    Rails.logger.info "ScrapeCreators API Response: #{response.code} - #{response.body[0..500]}"

    case response.code
    when 200
      OpenStruct.new(
        success?: true,
        data: response.parsed_response,
        error: nil
      )
    when 401
      OpenStruct.new(
        success?: false,
        data: nil,
        error: 'Invalid API key'
      )
    when 429
      OpenStruct.new(
        success?: false,
        data: nil,
        error: 'Rate limit exceeded'
      )
    else
      OpenStruct.new(
        success?: false,
        data: nil,
        error: "API error: #{response.code} - #{response.message} - #{response.body}"
      )
    end
  rescue => e
    Rails.logger.error "ScrapeCreators API Request Error: #{e.message}"
    OpenStruct.new(
      success?: false,
      data: nil,
      error: "Request failed: #{e.message}"
    )
  end

  def extract_locations_from_tweets(tweets_data)
    return [] unless tweets_data.is_a?(Array)

    locations = []
    tweets_data.each do |tweet|
      next unless tweet.is_a?(Hash)

      tweet_text = tweet['text'] || tweet['content'] || ''
      location_matches = extract_locations_from_text(tweet_text)
      locations.concat(location_matches)
    end

    locations.uniq.compact
  end

  def extract_locations_from_text(text)
    return [] if text.blank?

    locations = []

    # Location patterns in tweets
    location_patterns = [
      /\b(?:at|in|from|visiting|traveling to|live in|based in)\s+([A-Z][a-zA-Z\s,]+?)(?:\s|$|[.!?])/i,
      /📍\s*([A-Za-z\s,]+)/,  # Location emoji
      /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*),\s*([A-Z]{2}|[A-Za-z\s]+)/  # City, State/Country
    ]

    location_patterns.each do |pattern|
      matches = text.scan(pattern)
      matches.each do |match|
        location = match.is_a?(Array) ? match.first : match
        cleaned = clean_location(location)
        locations << cleaned if cleaned
      end
    end

    locations
  end

  def extract_location_from_user(user)
    return nil unless user.is_a?(Hash)

    # Try different possible location fields from the API response
    location_fields = %w[location bio description profile_location city country]

    location_fields.each do |field|
      location = user[field]&.to_s&.strip
      next if location.blank?

      # Basic location extraction from text
      if location_mentions_location?(location)
        return clean_location(location)
      end
    end

    nil
  end

  def location_mentions_location?(text)
    # Simple location detection patterns
    location_patterns = [
      /\b(?:from|in|at|based in|located in|lives? in)\s+([A-Za-z\s,]+)/i,
      /\b([A-Za-z]+(?:\s+[A-Za-z]+)*),\s*([A-Z]{2}|[A-Za-z\s]+)/,  # City, State/Country
      /\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)*)\b/  # Capitalized location names
    ]

    location_patterns.any? { |pattern| text.match?(pattern) }
  end

  def clean_location(location)
    # Remove common non-location text and clean up
    cleaned = location.gsub(/\b(?:from|in|at|based|located|lives?|born)\s+/i, '')
                     .gsub(/[^\w\s,.-]/, '')
                     .strip

    # Return if it looks like a real location (has letters and reasonable length)
    return cleaned if cleaned.length > 2 && cleaned.match?(/[A-Za-z]/)

    nil
  end
end