class LocationScrapingJob < ApplicationJob
  queue_as :default

  def perform(user_social_profile_id)
    profile = UserSocialProfile.find_by(id: user_social_profile_id)
    return unless profile

    Rails.logger.info "Starting location scraping for profile #{profile.id}"

    begin
      locations = profile.update_location_data!

      if locations
        Rails.logger.info "Successfully scraped #{locations.size} unique locations for profile #{profile.id}"

        # Optionally create city records for new locations
        create_city_records(locations)
      else
        Rails.logger.warn "Location scraping returned false for profile #{profile.id}"
      end
    rescue => e
      Rails.logger.error "Location scraping job failed for profile #{profile.id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def create_city_records(locations)
    locations.each do |location|
      next if location.blank?

      # Create city record if it doesn't exist
      City.find_or_create_by(name: location.strip.titleize) do |city|
        Rails.logger.info "Created new city: #{city.name}"
      end
    rescue => e
      Rails.logger.warn "Failed to create city record for '#{location}': #{e.message}"
    end
  end
end