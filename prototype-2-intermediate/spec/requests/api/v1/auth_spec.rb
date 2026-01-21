require 'rails_helper'

RSpec.describe 'Authentication', type: :request do
  let!(:user) { User.create!(email: 'test@test.com', password: '123456') }

  it 'returns a JWT token with valid credentials' do
    post '/api/v1/login', params: {
      email: user.email,
      password: '123456'
    }

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to have_key('token')
  end

  it 'returns unauthorized with invalid credentials' do
    post '/api/v1/login', params: {
      email: user.email,
      password: 'wrong'
    }

    expect(response).to have_http_status(:unauthorized)
  end
end
