class SocialConnection < ApplicationRecord
  belongs_to :user
  belongs_to :city

  validates :name, presence: true
  validates :social_media_type, presence: true
  validates :social_media_id, presence: true, uniqueness: { scope: :social_media_type }
end
