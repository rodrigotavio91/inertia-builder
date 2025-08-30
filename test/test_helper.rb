# frozen_string_literal: true

require 'rails'
require 'action_controller/railtie'

require 'jbuilder'
require 'inertia_rails'
require 'inertia_builder'
require 'active_support/testing/autorun'

ActiveSupport.test_order = :random

# Instantiate an Application in order to trigger the initializers
Class.new(Rails::Application) do
  config.secret_key_base = 'secret'
  config.eager_load = false
end.initialize!

# Touch AV::Base in order to trigger :action_view on_load hook before running the tests
ActionView::Base.inspect
