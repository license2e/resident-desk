log = File.new("logs/stdlog-debug.log", "a")
STDOUT.reopen(log)
STDERR.reopen(log)

$:.unshift File.expand_path("../lib", __FILE__)
$:.unshift File.expand_path("../app", __FILE__)
$:.unshift File.expand_path("../config", __FILE__)

require 'useragent'
require 'rack'
require 'rack-cache'
require 'rack-protection'
require 'haml'
require 'sinatra/base'
require 'sinatra/sessionauth'
require 'sinatra/content_for2'
require 'sinatra/head'
require 'action_mailer'
#require 'nokogiri'
require 'json'
require 'data_mapper'
#-----------
require 'controllers/app'

map '/' do 
  run App
end
