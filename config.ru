#\ -o 0.0.0.0
require 'rubygems'
require 'bundler'

Bundler.require

require './home_gtd'

run Sinatra::Application

