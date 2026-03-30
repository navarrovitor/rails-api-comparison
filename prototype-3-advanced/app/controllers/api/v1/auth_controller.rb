module Api
  module V1
    class AuthController < ApplicationController

      skip_before_action :authorize_request, only: [:login]

      def login
        user = User.find_by(email: params[:email])
        if user&.authenticate(params[:password])
          token = JsonWebToken.encode(user_id: user.id)
          render json: { token: token }
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end
    end
  end
end
