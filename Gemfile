source 'https://rubygems.org'

# Bundler should use whatever version of Ruby we're using
ruby "~> #{File.read('.ruby-version')}"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'

gem 'pg'

# Use Puma as the app server
gem 'puma', '~> 3.0'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
# gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-ui-rails'

# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Make $(document).ready work as expected, despite turbolinks weirdness
gem 'jquery-turbolinks'

# JavaScript Libraries
gem 'underscore-rails'

# Use Foundation for front-end stuff
gem 'foundation-rails'

# Use rabl and oj for json serialization
gem 'rabl'
gem 'oj'

# Google API for OAuth and getting interview results
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem "omniauth-rails_csrf_protection"

gem 'signet'
gem 'google-api-client', require: 'google/apis/sheets_v4'

# Assorted Ruby gems
gem 'faker'
gem 'httparty'

# Require a secure Nokogiri
gem "nokogiri", ">= 1.10.4"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug', platform: :mri

  # Set up environment from .env
  gem 'dotenv-rails'

  gem 'awesome_print'

  # Use pry for rails console
  gem 'pry-rails'

  gem 'binding_of_caller'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Improve the error message you get in the browser
  gem 'better_errors'
end

group :test do
  gem 'minitest', '~> 5.10.3'
  gem 'minitest-rails'
  gem 'minitest-reporters'
  gem 'minitest-spec-rails'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
