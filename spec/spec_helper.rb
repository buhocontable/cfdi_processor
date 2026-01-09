require 'coveralls'
Coveralls.wear!

require "bundler/setup"
require "cfdi_processor"
require "shoulda-matchers"
begin
  require "pry"
rescue LoadError, NameError
  # pry not available, skip it
end
require "support/xml_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include XmlHelper
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
  end
end