# frozen_string_literal: true

require_relative 'lib/inertia_builder/version'

Gem::Specification.new do |s|
  s.name     = 'inertia_builder'
  s.version  = InertiaBuilder::VERSION
  s.authors  = 'Rodrigo Lima'
  s.email    = 'rodrigotavio91@gmail.com'
  s.summary  = 'Create Inertia.js props via a Jbuilder-style DSL'
  s.homepage = 'https://github.com/rodrigotavio91/inertia-builder'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 3.0.0'

  s.add_dependency 'inertia_rails', '>= 3.5'
  s.add_dependency 'jbuilder', '>= 2.0'

  s.add_development_dependency 'rails', '>= 7.0.0'
  s.add_development_dependency 'rails-controller-testing'
  s.add_development_dependency 'rake'

  s.files = Dir['lib/**/*']
  s.test_files = Dir['test/**/*']

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/rodrigotavio91/inertia-builder/issues',
    'changelog_uri' => "https://github.com/rodrigotavio91/inertia-builder/releases/tag/v#{s.version}",
    'source_code_uri' => "https://github.com/rodrigotavio91/inertia-builder/tree/v#{s.version}",
    'rubygems_mfa_required' => 'true'
  }
end
