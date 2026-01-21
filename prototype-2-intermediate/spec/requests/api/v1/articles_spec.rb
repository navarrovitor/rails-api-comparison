require 'rails_helper'

RSpec.describe 'Articles API', type: :request do
  let!(:user) { User.create!(email: 'test@test.com', password: '123456') }
  let!(:token) { JsonWebToken.encode(user_id: user.id) }

  it 'denies access without token' do
    get '/api/v1/articles'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows access with valid token' do
    get '/api/v1/articles',
        headers: { 'Authorization' => "Bearer #{token}" }

    expect(response).to have_http_status(:ok)
  end
end
