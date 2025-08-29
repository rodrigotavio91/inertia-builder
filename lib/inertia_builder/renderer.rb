# frozen_string_literal: true

module InertiaBuilder
  class Renderer
    def initialize(view_context, props, component)
      @view_context = view_context
      @inertia_renderer = ::InertiaRails::Renderer.new(
        component,
        view_context.controller,
        view_context.request,
        view_context.response,
        view_context.controller.method(:render),
        props: props
      )
    end

    def render
      page = @inertia_renderer.send(:page)

      if @view_context.request.headers['X-Inertia']
        page.to_json
      else
        @view_context.controller.render_to_string(
          template: 'inertia',
          layout: false,
          locals: @inertia_renderer.send(:view_data).merge(page: page)
        )
      end
    end
  end
end
