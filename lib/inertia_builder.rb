# frozen_string_literal: true

require 'jbuilder/jbuilder_template'
require 'inertia_builder/handler'
require 'inertia_builder/controller'
require 'inertia_builder/renderer'
require 'inertia_builder/railtie'

class JbuilderTemplate
  self.template_lookup_options = { handlers: %i[inertia jbuilder] }
end

module InertiaBuilder
  class PropBuilder < JbuilderTemplate
    alias props attributes!

    def optional!(&block)
      _call_inertia_block(:optional, &block)
    end

    def always!(&block)
      _call_inertia_block(:always, &block)
    end

    def defer!(**opts, &block)
      _call_inertia_block(:defer, **opts, &block)
    end

    def method_missing(name, *args, &block)
      prop = self

      if @inertia_block
        method, opts = @inertia_block
        _set_value(name, ::InertiaRails.send(method, **opts) { prop.set!(name, *args, &block) })
      elsif !@in_scope
        # Lazy evaluate outermost properties.
        _set_value(name, -> { prop.set!(name, *args, &block); })
      else
        super
      end
    end

    private

    def _call_inertia_block(method, **opts)
      ::Kernel.raise "Nesting #{method}! in a #{@inertia_block[0]}! block is not allowed" if @inertia_block

      @inertia_block = [method, opts]
      yield
      @inertia_block = nil
    end

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

    def _scope
      @in_scope = true
      super
    ensure
      @in_scope = false
    end

    def _merge_values(current_value, updates)
      # Always override lazy evaluation procs.
      if current_value.is_a?(::Proc)
        updates
      else
        super
      end
    end
  end
end
