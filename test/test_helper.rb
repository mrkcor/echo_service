ENV['RACK_ENV'] = 'test'

require_relative '../echo_service'
require 'minitest/autorun'
require 'rack/test'
require 'nokogiri'
