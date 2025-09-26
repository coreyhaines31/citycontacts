class AddTwitterFieldsToUserSocialProfiles < ActiveRecord::Migration[8.0]
  def change
    unless column_exists? :user_social_profiles, :social_media_type
      add_column :user_social_profiles, :social_media_type, :string
      add_column :user_social_profiles, :social_media_user_id, :string
      add_column :user_social_profiles, :access_token, :string
      add_column :user_social_profiles, :refresh_token, :string
      add_column :user_social_profiles, :expires_at, :datetime
      
      add_index :user_social_profiles, [:user_id, :social_media_type], unique: true
      add_index :user_social_profiles, :social_media_user_id
    end
  end
end
