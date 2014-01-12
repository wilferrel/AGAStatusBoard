require 'rubygems'
require 'bundler' 
require './agaStatusBoard'
Bundler.setup

not_found do
  'Site does not exist.'
end

error do
  "Application error. Please try later."
end

configure do
    set :raise_errors, true
    set :show_exceptions, true
  end

run Sinatra::Application

