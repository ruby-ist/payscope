#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
mkdir -p "$HOME/.postgresql" && curl -o "$HOME/.postgresql/root.crt" "https://cockroachlabs.cloud/clusters/7ae464c2-e293-4708-957a-373ade476566/cert"
bundle exec rake db:migrate

# steps to seed the database
gem install faker
script/generate_seed_data --exchange-rates 8 --employees 10100 --invalid-employees 100
rails db:seed
