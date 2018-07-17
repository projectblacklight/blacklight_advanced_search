# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

require 'engine_cart'
EngineCart.load_application!

require 'rsolr'
require 'capybara/rspec'
require 'rspec/rails'
require 'capybara/rails'

RSpec.configure do |config|
  # Maintain this rspec2 behavior even in rspec3, until we
  # adjust our stuff. Deprecation warning was:
  # --------------------------------------------------------------------------------
  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to this feature using this
  # snippet:

  # RSpec.configure do |config|
  #   config.infer_spec_type_from_file_location!
  # end

  # If you wish to manually label spec types via metadata you can safely ignore
  # this warning and continue upgrading to RSpec 3 without addressing it.
  # --------------------------------------------------------------------------------
  config.infer_spec_type_from_file_location!
end
