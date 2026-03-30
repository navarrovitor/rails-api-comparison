# Use the app's configured cache store (Redis in production/development, memory in test)
Rack::Attack.cache.store = Rails.cache

# Rule 1 — General limit per IP: 300 requests per 5 minutes
Rack::Attack.throttle("req/ip", limit: 300, period: 5.minutes) do |req|
  req.ip
end

# Rule 2 — Limit per authenticated JWT token: 100 requests per minute
Rack::Attack.throttle("req/token", limit: 100, period: 1.minute) do |req|
  auth_header = req.get_header("HTTP_AUTHORIZATION")
  auth_header.split(" ").last if auth_header&.start_with?("Bearer ")
end

# Rule 3 — Login endpoint protection: 5 attempts per minute per IP
Rack::Attack.throttle("login/ip", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/api/v1/login" && req.post?
end

# Throttle response: 429 with JSON body
Rack::Attack.throttled_responder = lambda do |_req|
  [
    429,
    { "Content-Type" => "application/json" },
    [{ error: "Rate limit exceeded. Try again later." }.to_json]
  ]
end
