# frozen_string_literal: true

module InertiaBuilder
  class Handler
    def self.call(template, source = nil)
      source ||= template.source

      # Keep line numbers right in the error.
      %{__already_defined = defined?(prop); prop||=InertiaBuilder::PropBuilder.new(self);component=true;#{source};
      InertiaBuilder::Renderer.new(self, prop.props, component).render unless __already_defined}
    end
  end
end
