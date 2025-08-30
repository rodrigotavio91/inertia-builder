# frozen_string_literal: true

require 'test_helper'
require 'action_view/testing/resolvers'
require 'rails/controller/testing'

class TestController < ActionController::Base
  include InertiaBuilder::Controller

  def index; end
end

class ControllerTest < ActionController::TestCase
  include Rails::Controller::Testing::TemplateAssertions

  tests TestController

  def setup
    super

    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw { get 'index' => 'test#index' }

    resolver = ActionView::FixtureResolver.new(
      'layouts/application.html.erb' => '<html><body><%= yield %></body></html>',
      'test/index.html.inertia' => 'prop.content "content"'
    )

    @controller.prepend_view_path(resolver)
  end

  def teardown
    super
    @routes.clear!
  end

  def test_renders_index_html_inertia_for_a_standard_non_inertia_request
    get :index

    assert_response :success
    assert_template 'test/index'

    assert_equal 'text/html; charset=utf-8', response.content_type
    assert_nil response.headers['X-Inertia']

    assert_equal response.body, inertia_html_with_props(content: 'content')
  end

  def test_renders_index_html_inertia_for_an_inertia_request_with_json_headers
    @request.headers['X-Inertia'] = 'true'
    get :index

    assert_response :success
    assert_template 'test/index'

    assert_equal 'application/json; charset=utf-8', response.content_type
    assert_equal 'X-Inertia', response.headers['Vary']
    assert_equal 'true',      response.headers['X-Inertia']

    assert_equal response.body, inertia_json_with_props(content: 'content')
  end

  private

  def inertia_html_with_props(props)
    <<~HTML.chomp
      <html><body><div id="app" data-page="#{ERB::Util.html_escape(inertia_json_with_props(props))}"></div>
      </body></html>
    HTML
  end

  def inertia_json_with_props(props)
    {
      component: 'test/index',
      props:,
      url: '/index',
      version: nil,
      encryptHistory: false,
      clearHistory: false,
    }.to_json
  end
end
