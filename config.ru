require 'rubygems'
require 'bundler/setup'
require "#{File.dirname(__FILE__)}/app"

set :environment, ENV['RACK_ENV'].to_sym
set :app_file,  'app.rb'
disable :run
set :protection, :except => :frame_options


log = File.new("logs/sinatra.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

run Sinatra::Application