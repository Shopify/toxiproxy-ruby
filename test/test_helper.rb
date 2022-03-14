require 'minitest/autorun'
require_relative "../lib/toxiproxy"
require 'webmock/minitest'
require 'socket'
require 'timeout'

WebMock.disable!
