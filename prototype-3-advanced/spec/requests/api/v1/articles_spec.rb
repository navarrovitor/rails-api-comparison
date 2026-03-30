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

  describe 'cache behavior' do
    let!(:article) { Article.create!(title: 'Cached Article', content: 'Body') }

    it 'serves index from cache on second request without hitting the DB' do
      get '/api/v1/articles', headers: auth_headers
      expect(response).to have_http_status(:ok)

      expect(Article).not_to receive(:all)
      get '/api/v1/articles', headers: auth_headers
      expect(response).to have_http_status(:ok)
    end

    it 'invalidates index cache after POST and returns updated list' do
      get '/api/v1/articles', headers: auth_headers
      original_count = JSON.parse(response.body).length

      post '/api/v1/articles',
           params: { article: { title: 'New', content: 'New content' } },
           headers: auth_headers
      expect(response).to have_http_status(:created)

      get '/api/v1/articles', headers: auth_headers
      expect(JSON.parse(response.body).length).to eq(original_count + 1)
    end

    it 'invalidates article cache after PUT and returns updated data' do
      get "/api/v1/articles/#{article.id}", headers: auth_headers
      expect(JSON.parse(response.body)['title']).to eq('Cached Article')

      put "/api/v1/articles/#{article.id}",
          params: { article: { title: 'Updated Title' } },
          headers: auth_headers
      expect(response).to have_http_status(:ok)

      get "/api/v1/articles/#{article.id}", headers: auth_headers
      expect(JSON.parse(response.body)['title']).to eq('Updated Title')
    end

    it 'invalidates article cache after DELETE and record no longer exists' do
      get "/api/v1/articles/#{article.id}", headers: auth_headers
      expect(response).to have_http_status(:ok)

      delete "/api/v1/articles/#{article.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)

      expect(Article.exists?(article.id)).to be false
      expect(Rails.cache.read("articles/#{article.id}")).to be_nil
    end
  end
end
