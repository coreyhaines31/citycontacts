class AddLocationDataToUserSocialProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_social_profiles, :followers_locations, :text
    add_column :user_social_profiles, :following_locations, :text
    add_column :user_social_profiles, :last_scraped_at, :datetime
  end
end
