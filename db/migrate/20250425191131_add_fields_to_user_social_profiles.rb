class AddFieldsToUserSocialProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :user_social_profiles, :social_media_user_id, :string
  end
end
