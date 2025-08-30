# frozen_string_literal: true

module InertiaBuilder
  module Controller
    extend ActiveSupport::Concern

    included do
      layout -> { inertia_json_request? ? false : 'application' }

      before_action :force_json_response_with_html_template, if: -> { inertia_json_request? }
    end

    private

    def inertia_json_request?
      request.headers['X-Inertia'].present?
    end

    def force_json_response_with_html_template
      response.content_type = Mime[:json]
      response.headers['Vary'] = if response.headers['Vary'].blank?
                                   'X-Inertia'
                                 else
                                   "#{response.headers['Vary']}, X-Inertia"
                                 end
      response.set_header('X-Inertia', 'true')
    end
  end
end
