require 'rails_helper'

RSpec.describe 'Articles API', type: :request do
  let!(:user) { User.create!(email: 'test@test.com', password: '123456') }
  let!(:token) { JsonWebToken.encode(user_id: user.id) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{token}" } }

  it 'denies access without token' do
    get '/api/v1/articles'
    expect(response).to have_http_status(:unauthorized)
  end

  it 'allows access with valid token' do
    get '/api/v1/articles', headers: auth_headers
    expect(response).to have_http_status(:ok)
  end

  describe 'update' do
    let!(:article) { Article.create!(title: 'Original', content: 'Body') }

    it 'updates article with valid token' do
      put "/api/v1/articles/#{article.id}",
          params: { article: { title: 'Updated' } },
          headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'denies update without token' do
      put "/api/v1/articles/#{article.id}",
          params: { article: { title: 'Updated' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'destroy' do
    let!(:article) { Article.create!(title: 'To Delete', content: 'Body') }

    it 'destroys article with valid token' do
      delete "/api/v1/articles/#{article.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)
    end

    it 'denies destroy without token' do
      delete "/api/v1/articles/#{article.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
