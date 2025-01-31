# frozen_string_literal: true

require 'bundler/setup'
require_relative 'system/container'
require 'dry/events'
require 'dry/monitor/notifications'
require 'dry/system/dependency_graph'
require_relative './app'

Dry::System::DependencyGraph.register!(App)

ns = Dry::Container::Namespace.new('persistance') do
  register('users') { Array.new }
end
App.import(ns)

App.finalize!(freeze: false)
App[:dependency_graph].enable_realtime_calls!
App.freeze

use Rack::ContentType, "text/html"
use Rack::ContentLength

require 'dry/system/dependency_graph/middleware'
use Rack::ContentLength
use Dry::System::DependencyGraph::Middleware, container: App

run WebApp.new
