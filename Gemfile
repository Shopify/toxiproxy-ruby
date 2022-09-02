# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "rake"

group :test do
  gem "minitest"
  gem "webmock"
end

group :lint do
  gem "rubocop-minitest", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-shopify", require: false
  gem "rubocop", require: false
end
