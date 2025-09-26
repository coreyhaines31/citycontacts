class CreateUserSocialProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :user_social_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :social_media_type
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at

      t.timestamps
    end
  end
end
