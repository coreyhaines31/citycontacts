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
      query: { user: username_or_url }
    })

    handle_response(response)
  end

  # Get Twitter user's followers with location data
  def get_twitter_followers(username_or_url, limit: 100)
    response = self.class.get('/twitter/followers', {
      headers: headers,
      query: {
        user: username_or_url,
        limit: limit
      }
    })

    handle_response(response)
  end

  # Get Twitter user's following with location data
  def get_twitter_following(username_or_url, limit: 100)
    response = self.class.get('/twitter/following', {
      headers: headers,
      query: {
        user: username_or_url,
        limit: limit
      }
    })

    handle_response(response)
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

  # Get followers' locations for a Twitter user
  def get_followers_locations(username_or_url, limit: 100)
    followers_data = get_twitter_followers(username_or_url, limit: limit)
    return [] unless followers_data.success?

    extract_locations_from_users(followers_data.data)
  end

  # Get following users' locations for a Twitter user
  def get_following_locations(username_or_url, limit: 100)
    following_data = get_twitter_following(username_or_url, limit: limit)
    return [] unless following_data.success?

    extract_locations_from_users(following_data.data)
  end

  private

  def headers
    {
      'x-api-key' => @api_key,
      'Content-Type' => 'application/json'
    }
  end

  def handle_response(response)
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
        error: "API error: #{response.code} - #{response.message}"
      )
    end
  rescue => e
    OpenStruct.new(
      success?: false,
      data: nil,
      error: "Request failed: #{e.message}"
    )
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