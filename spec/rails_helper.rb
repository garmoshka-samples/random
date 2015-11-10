# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

def clean
  if User.find_by_name('admin')
    raise 'Seems, it is not a testing database, but test tries to clean User database'
  else
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean
  end
end

clean

def init(options = {})
  RSpec.configure do |config|
    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    config.include FactoryGirl::Syntax::Methods
    config.include Devise::TestHelpers, type: :controller

  #  config.include Capybara::DSL
  #  config.include Capybara::RSpecMatchers

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = !options[:disable_transactional_fixtures]

    # RSpec Rails can automatically mix in different behaviours to your tests
    # based on their file location, for example enabling you to call `get` and
    # `post` in specs under `spec/controllers`.
    #
    # You can disable this behaviour by removing the line below, and instead
    # explicitly tag your specs with their type, e.g.:
    #
    #     RSpec.describe UsersController, :type => :controller do
    #       # ...
    #     end
    #
    # The different available types are documented in the features, such as in
    # https://relishapp.com/rspec/rspec-rails/docs
    config.infer_spec_type_from_file_location!
  end
end

class WaitTimeout < StandardError
end

def wait_for(timeout = 5)
  start = Time.now
  x = yield
  until x
    if Time.now - start > timeout
      raise WaitTimeout
    end
    sleep(0.1)
    x = yield
  end
end

def parse(response)
  JSON.parse(response.body, symbolize_names: true)
end

def at_controller(cls)
  old_controller = @controller
  @controller = cls.new
  yield
  @controller = old_controller
end

def authenticate(request, token)
  request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(token)
end

def create_unordered_posts
  create :post, score: 4, recent_score: 7
  create :post, score: 7, recent_score: 5
  create :post, score: 3, recent_score: 5
  create :post, score: 5, recent_score: 3
  create :post, score: 6, recent_score: 9
end
