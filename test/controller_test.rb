# frozen_string_literal: true

require 'test_helper'
require 'action_view/testing/resolvers'

class TestController < ActionController::Base
  include InertiaBuilder::Controller

  layout 'application'

  def index; end

  def create
    respond_to do |format|
      format.html { render :create, status: :created }
      format.json { render :create, status: :created }
    end
  end
end

class ControllerTest < ActionController::TestCase
  tests TestController

  def setup
    super

    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get 'index' => 'test#index'
      post 'create' => 'test#create'
    end

    resolver = ActionView::FixtureResolver.new(
      'layouts/application.html.erb' => '<html><body><%= yield %></body></html>',
      'test/index.html.inertia' => 'prop.content "content"',
      'test/create.html.inertia' => 'prop.content "This is Inertia content"',
      'test/create.json.jbuilder' => 'json.content "This is JSON content"'
    )

    @controller.prepend_view_path(resolver)
  end

  def teardown
    super
    @routes.clear!
  end

  def test_renders_index_html_inertia_for_a_standard_non_inertia_request
    @request.headers['X-Inertia'] = nil
    get :index

    assert_response :success

    assert_equal 'text/html; charset=utf-8', response.content_type
    assert_nil response.headers['X-Inertia']

    assert_equal response.body, inertia_html_with_props(content: 'content')
  end

  def test_renders_index_html_inertia_for_an_inertia_request_with_json_headers
    @request.headers['X-Inertia'] = 'true'
    get :index

    assert_response :success

    # assert_equal 'application/json; charset=utf-8', response.content_type
    assert_equal 'X-Inertia', response.headers['Vary']
    assert_equal 'true',      response.headers['X-Inertia']

    assert_equal response.body, inertia_json_with_props(content: 'content')
  end

  def test_respects_respond_to_block
    @request.headers['X-Inertia'] = 'true'
    post :create

    assert_response :created
    assert_equal response.body, inertia_json_with_props(
      { content: 'This is Inertia content' },
      component: 'test/create',
      url: '/create'
    )

    post :create, format: :json

    assert_response :created
    assert_equal response.body, { content: 'This is JSON content' }.to_json
  end

  private

  def inertia_html_with_props(props)
    <<~HTML.chomp
      <html><body><div id="app" data-page="#{ERB::Util.html_escape(inertia_json_with_props(props))}"></div>
      </body></html>
    HTML
  end

  def inertia_json_with_props(props, opts = {})
    {
      component: opts.fetch(:component, 'test/index'),
      props: { errors: {} }.merge(props),
      url: opts.fetch(:url, '/index'),
      version: nil,
      encryptHistory: false,
      clearHistory: false
    }.to_json
  end
end
