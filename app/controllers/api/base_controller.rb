module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :ensure_json_request
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
    rescue_from ActionController::ParameterMissing, with: :render_bad_request

    protected

    def render_not_found(exception)
      render_error(exception.message, :not_found)
    end

    def render_unprocessable_entity(exception)
      render_error(exception.record.errors.full_messages, :unprocessable_entity)
    end

    def render_bad_request(exception)
      render_error("Required parameter missing: #{exception.param}", :bad_request)
    end

    def render_error(errors, status)
      render json: { errors: Array(errors) }, status: status
    end

    def ensure_json_request
      return if request.format == :json
      raise ActionController::RoutingError, 'Not supported format'
    end
  end
end
