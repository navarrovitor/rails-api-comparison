require 'swagger_helper'

RSpec.describe 'Authentication API', type: :request do
  path '/api/v1/login' do
    post 'User login' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: %w[email password]
      }

      response '200', 'token generated' do
        before { User.create!(email: 'test@test.com', password: '123456') }
        let(:credentials) { { email: 'test@test.com', password: '123456' } }
        let(:Authorization) { nil }
        run_test!
      end

      response '401', 'invalid credentials' do
        let(:credentials) { { email: 'test@test.com', password: 'wrong' } }
        let(:Authorization) { nil }
        run_test!
      end

      response '429', 'rate limit exceeded' do
        schema type: :object,
               properties: { error: { type: :string } },
               required: ['error']
      end
    end
  end
end
