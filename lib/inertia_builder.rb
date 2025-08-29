# frozen_string_literal: true

require 'inertia_rails'
require 'inertia_builder/version'
require 'inertia_builder/handler'
require 'inertia_builder/controller'
require 'inertia_builder/renderer'
require 'inertia_builder/railtie' if defined?(Rails)

module InertiaBuilder
  class PropBuilder < JbuilderTemplate
    alias props attributes!

    private

    def _render_partial(options)
      options[:handlers] = [:inertia]
      options[:locals][:prop] = self
      @context.render options
    end

    def _render_active_model_partial(object)
      @context.render object, prop: self, handlers: [:inertia]
    end
  end
end
