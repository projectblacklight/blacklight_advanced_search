# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require 'engine_cart'
EngineCart.load_application!

require 'rsolr'
require 'capybara/rspec'
require 'rspec/rails'
require 'capybara/rails'

RSpec.configure(&:infer_spec_type_from_file_location!)
