FactoryBot.define do
  factory :user_social_profile do
    user { nil }
    social_media_type { "MyString" }
    access_token { "MyString" }
    refresh_token { "MyString" }
    expires_at { "2025-04-21 14:50:24" }
  end
end
