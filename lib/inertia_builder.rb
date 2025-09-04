# frozen_string_literal: true

require 'jbuilder/jbuilder_template'
require 'inertia_builder/handler'
require 'inertia_builder/controller'
require 'inertia_builder/renderer'
require 'inertia_builder/railtie' if defined?(Rails)

class JbuilderTemplate
  self.template_lookup_options = { handlers: %i[inertia jbuilder] }
end

module InertiaBuilder
  class PropBuilder < JbuilderTemplate
    alias props attributes!

    private

    def _render_partial_with_options(options)
      options[:locals] ||= options.except(:partial, :as, :collection, :cached)
      options[:locals][:prop] = self
      super(options)
    end

    def _render_partial(options)
      options[:locals][:prop] = self
      @context.render options
    end

    def _render_active_model_partial(object)
      @context.render object, prop: self
    end
  end
end
