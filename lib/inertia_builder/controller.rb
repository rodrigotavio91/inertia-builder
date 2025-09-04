# frozen_string_literal: true

module InertiaBuilder
  module Controller
    extend ActiveSupport::Concern

    included do
      before_action :format_inertia_json_response, if: -> { inertia_json_request? }
    end

    private

    def format_inertia_json_response
      response.headers['Vary'] = if response.headers['Vary'].blank?
                                   'X-Inertia'
                                 else
                                   "#{response.headers['Vary']}, X-Inertia"
                                 end
      response.set_header('X-Inertia', 'true')
    end

    def action_has_layout?
      !inertia_json_request? && super
    end

    def inertia_json_request?
      request.headers['X-Inertia'] == 'true'
    end
  end
end
