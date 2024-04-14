#!/usr/bin/env ruby

require 'bundler'
Bundler.setup(:default)

require 'logger'

$LOAD_PATH.unshift ::File.expand_path(::File.dirname(__FILE__) + '/lib')
require 'qmore-server'

use Rack::ShowExceptions
run Qless::Server.new(Qmore.client)
