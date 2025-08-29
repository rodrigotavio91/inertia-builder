# frozen_string_literal: true

require 'rails/railtie'

module InertiaBuilder
  class Railtie < ::Rails::Railtie
    initializer :inertia_builder do
      ActiveSupport.on_load(:action_controller) do
        include InertiaBuilder::Controller
      end

      ActiveSupport.on_load(:action_view) do
        ActionView::Template.register_template_handler :inertia, InertiaBuilder::Handler
      end
    end
  end
end
