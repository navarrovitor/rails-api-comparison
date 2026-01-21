require 'swagger_helper'

RSpec.describe 'Articles API', type: :request do
  path '/api/v1/articles' do

    get 'List articles' do
      tags 'Articles'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'articles listed' do
        let(:Authorization) do
          user = User.create!(email: 'test@test.com', password: '123456')
          token = JsonWebToken.encode(user_id: user.id)
          "Bearer #{token}"
        end

        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create article' do
      tags 'Articles'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      parameter name: :article, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          content: { type: :string }
        },
        required: %w[title content]
      }

      response '201', 'article created' do
        let(:Authorization) do
          user = User.create!(email: 'test@test.com', password: '123456')
          token = JsonWebToken.encode(user_id: user.id)
          "Bearer #{token}"
        end

        let(:article) do
          { title: 'Test', content: 'Content' }
        end

        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end
