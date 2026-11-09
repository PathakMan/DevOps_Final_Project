class ApplicationController < ActionController::Base
  # Disable CSRF token checks for JSON API requests so curl/Postman works easily
  protect_from_forgery with: :null_session, if: -> { request.format.json? }
end