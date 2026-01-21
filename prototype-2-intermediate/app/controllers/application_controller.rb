class ApplicationController < ActionController::API
  before_action :authorize_request

  private

  def authorize_request
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    decoded = JsonWebToken.decode(header)

    @current_user = User.find(decoded[:user_id]) if decoded
    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end
end
