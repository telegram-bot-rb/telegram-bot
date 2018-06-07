require 'pathname'
require 'pry'
require 'rspec/its'

if ENV['CI']
  require 'coveralls'
  Coveralls.wear!
elsif ENV.key?('COV')
  require 'simplecov'
  SimpleCov.start
end

GEM_ROOT = Pathname.new File.expand_path('../..', __FILE__)

$LOAD_PATH.unshift GEM_ROOT.join('lib')
require 'telegram/bot'
require 'telegram/bot/updates_controller/rspec_helpers'
require 'telegram/bot/types'
require 'active_support/json'

Dir[GEM_ROOT.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    # be_bigger_than(2).and_smaller_than(4).description
    #   # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #   # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # This config option will be enabled by default on RSpec 4,
  # but for reasons of backwards compatibility, you have to
  # set it on RSpec 3.
  #
  # It causes the host group and examples to inherit metadata
  # from the shared context.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # These two settings work together to allow you to limit a spec run
  # to individual examples or groups you care about by tagging them with
  # `:focus` metadata. When nothing is tagged with `:focus`, all examples
  # get run.
  #
  # Use `FULL=true bin/rspec` to disable filters.
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  # Limits the available syntax to the non-monkey patched syntax that is recommended.
  # For more details, see:
  #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
  #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://myronmars.to/n/dev-blog/2014/05/notable-changes-in-rspec-3#new__config_option_to_disable_rspeccore_monkey_patching
  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  config.default_formatter = 'doc' if config.files_to_run.one?

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  # config.profile_examples = 3

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  # Make it more convenient.
  require 'bigdecimal'
  BigDecimal.class_eval do
    alias_method :inspect_orig, :inspect
    alias_method :inspect, :to_s
  end
end
