class City < ApplicationRecord
  has_many :social_connections
  has_many :users, through: :social_connections

  validates :name, presence: true
  validates :country, presence: true
end
