# encoding: utf-8

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), *%w{ .. lib }))
require 'rspec'
require 'rubocop'
require 'rubocop/formatter/checkstyle_formatter'
