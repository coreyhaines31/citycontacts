FactoryBot.define do
  factory :social_connection do
    user { nil }
    city { nil }
    name { "MyString" }
    profile_picture { "MyString" }
    social_media_type { "MyString" }
    social_media_id { "MyString" }
  end
end
