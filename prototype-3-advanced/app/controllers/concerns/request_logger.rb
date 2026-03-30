module RequestLogger
  extend ActiveSupport::Concern

  included do
    after_action :log_request
  end

  private

  def log_request
    duration_ms = ((Time.now - request.env["action_dispatch.request.start_time"]) * 1000).round(2) rescue nil

    Rails.logger.info({
      method: request.method,
      path: request.path,
      status: response.status,
      duration_ms: duration_ms,
      user_id: @current_user&.id,
      cache: cache_hit? ? "hit" : "miss"
    }.to_json)
  end

  def cache_hit?
    defined?(@cache_hit) ? @cache_hit : false
  end
end
