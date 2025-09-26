require 'rails_helper'

RSpec.describe ScrapeCreatorsService, type: :service do
  let(:service) { described_class.new }

  before do
    allow(Rails.application.credentials).to receive(:scrape_creators).and_return(
      OpenStruct.new(api_key: 'test_api_key')
    )
  end

  describe '#initialize' do
    it 'initializes with API key from credentials' do
      expect(service.instance_variable_get(:@api_key)).to eq('test_api_key')
    end

    it 'raises error when API key is not configured' do
      allow(Rails.application.credentials).to receive(:scrape_creators).and_return(nil)
      expect { described_class.new }.to raise_error('ScrapeCreators API key not configured')
    end
  end

  describe '#extract_locations_from_users' do
    let(:users_data) do
      [
        { 'location' => 'New York, NY' },
        { 'bio' => 'Living in San Francisco' },
        { 'description' => 'Based in Los Angeles, CA' },
        { 'location' => '' },
        { 'location' => nil }
      ]
    end

    it 'extracts unique locations from user data' do
      locations = service.extract_locations_from_users(users_data)
      expect(locations).to be_an(Array)
      expect(locations).to include('New York, NY')
    end

    it 'handles empty or invalid data' do
      expect(service.extract_locations_from_users([])).to eq([])
      expect(service.extract_locations_from_users(nil)).to eq([])
    end
  end

  describe '#get_twitter_profile' do
    let(:mock_response) do
      double('response',
             code: 200,
             parsed_response: { 'data' => { 'username' => 'testuser' } }
      )
    end

    before do
      allow(ScrapeCreatorsService).to receive(:get).and_return(mock_response)
    end

    it 'makes request to Twitter profile endpoint' do
      expect(ScrapeCreatorsService).to receive(:get).with(
        '/twitter/profile',
        {
          headers: {
            'x-api-key' => 'test_api_key',
            'Content-Type' => 'application/json'
          },
          query: { user: 'testuser' }
        }
      )

      service.get_twitter_profile('testuser')
    end

    it 'returns successful response object' do
      result = service.get_twitter_profile('testuser')
      expect(result.success?).to be_truthy
      expect(result.data).to include('data' => { 'username' => 'testuser' })
    end
  end

  describe 'error handling' do
    let(:error_response) do
      double('response', code: 401, message: 'Unauthorized', parsed_response: {})
    end

    before do
      allow(ScrapeCreatorsService).to receive(:get).and_return(error_response)
    end

    it 'handles 401 errors' do
      result = service.get_twitter_profile('testuser')
      expect(result.success?).to be_falsy
      expect(result.error).to eq('Invalid API key')
    end
  end
end