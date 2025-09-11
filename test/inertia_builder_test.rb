require 'test_helper'
require 'action_view'
require 'active_model'
require 'action_view/testing/resolvers'

class User < Struct.new(:id, :first_name, :last_name, :email)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
end

class Item < Struct.new(:id, :title)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
end

class InertiaBuilderTest < Minitest::Test
  USER_PARTIAL = <<~INERTIA
    prop.id user.id
    prop.first_name user.first_name
    prop.last_name user.last_name
    prop.email user.email
  INERTIA

  ITEM_PARTIAL = <<~INERTIA
    prop.id item.id
    prop.title item.title
  INERTIA

  PARTIALS = {
    'users/_user.html.inertia' => USER_PARTIAL,
    'items/_item.html.inertia' => ITEM_PARTIAL
  }

  def test_basic_html_rendering
    result = render_view('prop.hello "World"')
    assert_equal inertia_html_with_props({ hello: 'World' }), result
  end

  def test_basic_json_rendering
    result = render_view('prop.hello "World"', json: true)
    assert_equal inertia_json_with_props({ hello: 'World' }), result
  end

  def test_nested_prop
    template = <<~INERTIA
      prop.product do
        prop.id 10
        prop.name 'Keyboard'
        prop.price 29.99
      end
    INERTIA

    expected_props = {
      product: {
        id: 10,
        name: 'Keyboard',
        price: 29.99
      }
    }

    assert_equal inertia_json_with_props(expected_props), render_view(template, json: true)
    assert_equal inertia_html_with_props(expected_props), render_view(template)
  end

  def test_collection_prop
    products = [
      {
        id: 10,
        name: 'Keyboard',
        price: 29.99
      },
      {
        id: 11,
        name: 'Monitor',
        price: 599.00
      }
    ]

    template = <<~INERTIA
      prop.products @products do |product|
        prop.id product.fetch(:id)
        prop.name product.fetch(:name)
        prop.price product.fetch(:price)
      end
    INERTIA

    expected_props = { products: products }

    assert_equal inertia_json_with_props(expected_props),
                 render_view(template, assigns: { products: products }, json: true)
    assert_equal inertia_html_with_props(expected_props), render_view(template, assigns: { products: products })
  end

  def test_basic_partial_prop
    user = User.new({ id: 42, first_name: 'John', last_name: 'Doe', email: 'john@email.com' })

    template = <<~INERTIA
      prop.user do
        prop.partial! 'users/user', user: @user
      end
    INERTIA

    expected_props = { user: user }

    assert_equal inertia_json_with_props(expected_props), render_view(template, assigns: { user: user }, json: true)
    assert_equal inertia_html_with_props(expected_props), render_view(template, assigns: { user: user })
  end

  def test_collection_partial_prop
    users = [
      User.new({ id: 42, first_name: 'John', last_name: 'Doe', email: 'john@email.com' }),
      User.new({ id: 43, first_name: 'Jane', last_name: 'Smith', email: 'jane@email.com' })
    ]

    template = <<~INERTIA
      prop.users @users do |user|
        prop.partial! user
      end
    INERTIA

    expected_props = { users: users }

    assert_equal inertia_html_with_props(expected_props), render_view(template, assigns: { users: users })
    assert_equal inertia_json_with_props(expected_props), render_view(template, assigns: { users: users }, json: true)
  end

  def test_shorthand_collection_partial_prop
    users = [
      User.new({ id: 42, first_name: 'John', last_name: 'Doe', email: 'john@email.com' }),
      User.new({ id: 43, first_name: 'Jane', last_name: 'Smith', email: 'jane@email.com' })
    ]

    items = [
      Item.new({ id: 1, title: 'Item 1' }),
      Item.new({ id: 2, title: 'Item 2' })
    ]

    template = <<~INERTIA
      prop.data do
        prop.users @users, partial: 'users/user', as: :user
        prop.items @items, partial: 'items/item', as: :item
      end
    INERTIA

    expected_props = { data: { users: users, items: items } }

    assert_equal inertia_json_with_props(expected_props),
                 render_view(template, assigns: { users: users, items: items }, json: true)
    assert_equal inertia_html_with_props(expected_props), render_view(template, assigns: { users: users, items: items })
  end

  def test_nil_prop_block
    template = <<~INERTIA
      prop.current_user do
        prop.nil!
      end
    INERTIA

    expected_props = { current_user: nil }

    assert_equal inertia_html_with_props(expected_props), render_view(template)
    assert_equal inertia_json_with_props(expected_props), render_view(template, json: true)
  end

  def test_optional_block
    template = <<~INERTIA
      prop.id 1
      prop.optional! do
        prop.user 'User'
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'user,calculation',
      'X-Inertia-Partial-Component' => '/'
    }
    assert_equal inertia_json_with_props({ id: 1 }), render_view(template, json: true)
    assert_equal inertia_json_with_props({ user: 'User', calculation: 'Calculation' }),
                 render_view(template, json: true, headers: partial_headers)
  end

  def test_always_block
    template = <<~INERTIA
      prop.id 1
      prop.always! do
        prop.user 'User'
      end
      prop.optional! do
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'calculation',
      'X-Inertia-Partial-Component' => '/'
    }
    assert_equal inertia_json_with_props({ id: 1, user: 'User' }), render_view(template, json: true)
    assert_equal inertia_json_with_props({ user: 'User', calculation: 'Calculation' }),
                 render_view(template, json: true, headers: partial_headers)
  end

  def test_defer_block
    template = <<~INERTIA
      prop.id 1
      prop.defer! do
        prop.user 'User'
        prop.calculation 'Calculation'
      end
    INERTIA

    assert_equal inertia_json_with_props({ id: 1 }, deferredProps: { default: %w[user calculation] }),
                 render_view(template, json: true)
  end

  def test_defer_block_grouping
    template = <<~INERTIA
      prop.id 1
      prop.defer! group: 'group1' do
        prop.user 'User'
      end
      prop.defer! group: 'group2' do
        prop.calculation 'Calculation'
      end
    INERTIA

    assert_equal inertia_json_with_props({ id: 1 }, deferredProps: { group1: ['user'], group2: ['calculation'] }),
                 render_view(template, json: true)
  end

  def test_defer_block_fetching
    template = <<~INERTIA
      prop.id 1
      prop.defer! do
        prop.user 'User'
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'user,calculation',
      'X-Inertia-Partial-Component' => '/'
    }

    assert_equal inertia_json_with_props({ user: 'User', calculation: 'Calculation' }),
                 render_view(template, json: true, headers: partial_headers)
  end

  private

  def render_view(source, **opts)
    req = ActionDispatch::TestRequest.create
    req.headers.merge!(opts[:headers] || {})
    req.headers['X-Inertia'] = 'true' if opts[:json]

    controller = ActionView::TestCase::TestController.new
    controller.request = req

    resolver = ActionView::FixtureResolver.new(PARTIALS.merge('source.html.inertia' => source))
    lookup = ActionView::LookupContext.new([resolver], {}, [''])

    view = ActionView::Base.with_empty_template_cache.new(lookup, opts[:assigns] || [], controller)

    view.render(template: 'source')
  end

  def inertia_html_with_props(props)
    <<~HTML
      <div id="app" data-page="#{ERB::Util.html_escape(inertia_json_with_props(props))}"></div>
    HTML
  end

  def inertia_json_with_props(props, **extra_fields)
    {
      component: '/',
      props: { errors: {} }.merge(props),
      url: '/',
      version: nil,
      encryptHistory: false,
      clearHistory: false
    }.merge(extra_fields).to_json
  end
end
