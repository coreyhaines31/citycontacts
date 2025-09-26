class ApifyScraperService
  include HTTParty

  base_uri 'https://api.apify.com/v2'

  def initialize
    @api_token = Rails.application.credentials.apify&.api_token
    raise 'Apify API token not configured' unless @api_token
  end

  # Scrape followers of a Twitter user using Apify's Twitter Followers Scraper
  def scrape_twitter_followers(username, max_followers: 100)
    actor_id = 'xtcodetech/twitter-x-followers-scraper'

    run_input = {
      profiles: [username],
      maxFollowers: max_followers,
      includeFollowersInfo: true
    }

    # Start the scraper
    response = self.class.post("/acts/#{actor_id}/runs", {
      headers: {
        'Authorization' => "Bearer #{@api_token}",
        'Content-Type' => 'application/json'
      },
      body: run_input.to_json
    })

    if response.success?
      run_id = response.parsed_response['data']['id']
      wait_for_completion(run_id)
    else
      Rails.logger.error "Apify API Error: #{response.code} - #{response.body}"
      nil
    end
  end

  # Scrape following of a Twitter user
  def scrape_twitter_following(username, max_following: 100)
    # Similar to followers but for following list
    # Implementation would depend on the specific Apify actor used
  end

  private

  def wait_for_completion(run_id, max_wait: 300)
    start_time = Time.current

    loop do
      status_response = self.class.get("/actor-runs/#{run_id}", {
        headers: { 'Authorization' => "Bearer #{@api_token}" }
      })

      if status_response.success?
        status = status_response.parsed_response.dig('data', 'status')

        case status
        when 'SUCCEEDED'
          return get_results(run_id)
        when 'FAILED', 'TIMED-OUT', 'ABORTED'
          Rails.logger.error "Apify run failed with status: #{status}"
          return nil
        end
      end

      break if Time.current - start_time > max_wait
      sleep(5)
    end

    Rails.logger.error "Apify run timed out"
    nil
  end

  def get_results(run_id)
    response = self.class.get("/actor-runs/#{run_id}/dataset/items", {
      headers: { 'Authorization' => "Bearer #{@api_token}" }
    })

    if response.success?
      followers_data = response.parsed_response
      extract_locations_from_followers(followers_data)
    else
      Rails.logger.error "Failed to get Apify results: #{response.body}"
      []
    end
  end

  def extract_locations_from_followers(followers_data)
    return [] unless followers_data.is_a?(Array)

    locations = []
    followers_data.each do |follower|
      next unless follower.is_a?(Hash)

      # Extract location from follower profile
      location_fields = %w[location bio description]
      location_fields.each do |field|
        location = follower[field]&.to_s&.strip
        next if location.blank?

        cleaned_location = clean_location(location)
        locations << cleaned_location if cleaned_location
      end
    end

    locations.uniq.compact
  end

  def clean_location(location)
    # Clean up location text
    cleaned = location.gsub(/[^\w\s,.-]/, '').strip
    return cleaned if cleaned.length > 2 && cleaned.match?(/[A-Za-z]/)
    nil
  end
end