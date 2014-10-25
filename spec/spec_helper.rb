require 'test_helpers'

RSpec.configure do |c|
  c.include TestHelpers
  c.expect_with :rspec do |config|
    config.syntax = [:should, :expect]
  end
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
end