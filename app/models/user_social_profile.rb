class UserSocialProfile < ApplicationRecord
  belongs_to :user

  validates :social_media_type, presence: true
  validates :access_token, presence: true
  validates :user_id, uniqueness: { scope: :social_media_type }
end
