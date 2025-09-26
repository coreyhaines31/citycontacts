require 'rails_helper'

RSpec.describe LocationScrapingJob, type: :job do
  let(:user) { create(:user) }
  let(:profile) { create(:user_social_profile, user: user, social_media_type: 'twitter', twitter_username: 'testuser') }

  describe '#perform' do
    context 'when profile exists' do
      it 'calls update_location_data! on the profile' do
        expect_any_instance_of(UserSocialProfile).to receive(:update_location_data!)
          .and_return(['New York', 'San Francisco'])

        described_class.new.perform(profile.id)
      end

      it 'creates city records for new locations' do
        allow_any_instance_of(UserSocialProfile).to receive(:update_location_data!)
          .and_return(['New York', 'San Francisco'])

        expect do
          described_class.new.perform(profile.id)
        end.to change(City, :count).by(2)

        expect(City.find_by(name: 'New York')).to be_present
        expect(City.find_by(name: 'San Francisco')).to be_present
      end

      it 'handles errors gracefully' do
        allow_any_instance_of(UserSocialProfile).to receive(:update_location_data!)
          .and_raise(StandardError.new('API error'))

        expect do
          described_class.new.perform(profile.id)
        end.to raise_error('API error')
      end
    end

    context 'when profile does not exist' do
      it 'returns early without error' do
        expect do
          described_class.new.perform(999)
        end.not_to raise_error
      end
    end
  end
end