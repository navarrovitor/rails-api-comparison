require 'rails_helper'

RSpec.describe 'Rate Limiting', type: :request do
  let!(:user) { User.create!(email: 'test@test.com', password: '123456') }
  let!(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    # Ensure Rack::Attack is enabled in tests
    Rack::Attack.enabled = true
    # Use the app's memory cache for throttle counters in tests
    Rack::Attack.cache.store = Rails.cache
  end

  after do
    Rack::Attack.enabled = false
  end

  describe 'login endpoint throttle' do
    it 'allows requests within the limit' do
      post '/api/v1/login', params: { email: user.email, password: '123456' }
      expect(response).not_to have_http_status(429)
    end

    it 'returns 429 after exceeding 5 login attempts per minute from same IP' do
      5.times do
        post '/api/v1/login', params: { email: user.email, password: 'wrong' }
      end

      post '/api/v1/login', params: { email: user.email, password: 'wrong' }
      expect(response).to have_http_status(429)
      expect(JSON.parse(response.body)['error']).to eq('Rate limit exceeded. Try again later.')
    end
  end

  describe 'token throttle' do
    it 'returns 429 after exceeding 100 requests per minute with same token' do
      100.times do
        get '/api/v1/articles', headers: auth_headers
      end

      get '/api/v1/articles', headers: auth_headers
      expect(response).to have_http_status(429)
      expect(JSON.parse(response.body)['error']).to eq('Rate limit exceeded. Try again later.')
    end
  end

  describe 'general IP throttle' do
    it 'requests within the limit respond normally' do
      get '/api/v1/articles', headers: auth_headers
      expect(response).not_to have_http_status(429)
    end
  end
end
