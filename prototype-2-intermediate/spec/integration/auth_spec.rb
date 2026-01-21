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
        let(:credentials) { { email: 'test@test.com', password: '123456' } }
        run_test!
      end

      response '401', 'invalid credentials' do
        let(:credentials) { { email: 'test@test.com', password: 'wrong' } }
        run_test!
      end
    end
  end
end
