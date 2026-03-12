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

Paginator = Struct.new(:current, :previous, :next, :param_name, keyword_init: true)

class PaginatorAdapter
  def match?(metadata)
    metadata.is_a?(Paginator)
  end

  def call(metadata, **_options)
    {
      page_name: metadata.param_name,
      previous_page: metadata.previous,
      next_page: metadata.next,
      current_page: metadata.current
    }
  end
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
        prop.user do
          prop.id 1
          prop.email 'user@email.com'
        end
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'user,calculation',
      'X-Inertia-Partial-Component' => '/'
    }
    assert_equal inertia_json_with_props({ id: 1 }), render_view(template, json: true)
    assert_equal inertia_json_with_props({ user: { id: 1, email: 'user@email.com' }, calculation: 'Calculation' }),
                 render_view(template, json: true, headers: partial_headers)
  end

  def test_always_block
    template = <<~INERTIA
      prop.id 1
      prop.always! do
        prop.user do
          prop.id 1
          prop.email 'user@email.com'
        end
      end
      prop.optional! do
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'calculation',
      'X-Inertia-Partial-Component' => '/'
    }
    assert_equal inertia_json_with_props({ id: 1, user: { id: 1, email: 'user@email.com' } }),
                 render_view(template, json: true)
    assert_equal inertia_json_with_props({ user: { id: 1, email: 'user@email.com' }, calculation: 'Calculation' }),
                 render_view(template, json: true, headers: partial_headers)
  end

  def test_defer_block
    template = <<~INERTIA
      prop.id 1
      prop.defer! do
        prop.user do
          prop.id 1
          prop.email 'user@email.com'
        end
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
    user = User.new({ id: 1, email: 'user@email.com' })

    template = <<~INERTIA
      prop.id 1
      prop.defer! do
        prop.user do
          prop.partial! @user
        end
        prop.calculation 'Calculation'
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'user,calculation',
      'X-Inertia-Partial-Component' => '/'
    }

    assert_equal inertia_json_with_props({ user: user, calculation: 'Calculation' }),
                 render_view(template, assigns: { user: user }, json: true, headers: partial_headers)
  end

  def test_scroll_block
    users = [
      User.new(id: 1, first_name: 'John', last_name: 'Smith', email: 'john@email.com'),
      User.new(id: 2, first_name: 'Jane', last_name: 'Smith', email: 'jane@email.com')
    ]

    template = <<~INERTIA
      prop.id 1
      prop.scroll!(page_name: 'page', current_page: 1, previous_page: nil, next_page: 2) do
        prop.users @users, partial: 'users/user', as: :user
      end
    INERTIA

    expected = inertia_json_with_props(
      { id: 1, users: users },
      scrollProps: { users: { pageName: 'page', previousPage: nil, nextPage: 2, currentPage: 1, reset: false } },
      mergeProps: ['users']
    )

    assert_equal expected, render_view(template, assigns: { users: users }, json: true)
  end

  def test_scroll_block_fetching
    users = [
      User.new(id: 3, first_name: 'Alice', last_name: 'Jones', email: 'alice@email.com'),
      User.new(id: 4, first_name: 'Bob', last_name: 'Brown', email: 'bob@email.com')
    ]

    template = <<~INERTIA
      prop.id 1
      prop.scroll!(page_name: 'page', current_page: 2, previous_page: 1, next_page: 3) do
        prop.users @users, partial: 'users/user', as: :user
      end
    INERTIA

    partial_headers = {
      'X-Inertia-Partial-Data' => 'users',
      'X-Inertia-Partial-Component' => '/'
    }
    expected = inertia_json_with_props(
      { users: users },
      scrollProps: { users: { pageName: 'page', previousPage: 1, nextPage: 3, currentPage: 2, reset: false } },
      mergeProps: ['users']
    )

    assert_equal expected, render_view(template, assigns: { users: users }, json: true, headers: partial_headers)
  end

  def test_scroll_block_with_metadata_extractor
    users = [
      User.new(id: 1, first_name: 'John', last_name: 'Smith', email: 'john@email.com')
    ]

    paginator = Paginator.new(current: 1, previous: nil, next: 2, param_name: 'p')

    template = <<~INERTIA
      prop.id 1
      prop.scroll!(@paginator) do
        prop.users @users, partial: 'users/user', as: :user
      end
    INERTIA

    with_scroll_metadata_adapater(PaginatorAdapter) do
      expected = inertia_json_with_props(
        { id: 1, users: users },
        scrollProps: { users: { pageName: 'p', previousPage: nil, nextPage: 2, currentPage: 1, reset: false } },
        mergeProps: ['users']
      )

      assert_equal expected, render_view(template, assigns: { users: users, paginator: paginator }, json: true)
    end
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

  def with_scroll_metadata_adapater(adapter_class)
    original_adapters = InertiaRails::ScrollMetadata.adapters.dup
    InertiaRails::ScrollMetadata.register_adapter(adapter_class)
    yield
  ensure
    InertiaRails::ScrollMetadata.adapters = original_adapters
  end
end
