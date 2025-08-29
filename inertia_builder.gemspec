# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'inertia_builder'
  s.version     = '0.1.0'
  s.summary     = 'Tiny Rails template handler for .inertia files'
  s.description = 'Registers a .rodrigo ActionView handler with a toy DSL.'
  s.authors     = ['Rodrigo Lima']
  s.files       = Dir['lib/**/*']
  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'inertia_rails', '>= 3.5'
  s.add_dependency 'jbuilder', '>= 2.7'
end
