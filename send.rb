#!/usr/bin/env ruby
require "./lib/sendtodns.rb"
require "logging"
require "resque"

Logging.color_scheme( 'bright',
  :levels => {
    :info  => :green,
    :warn  => :yellow,
    :error => :red,
    :fatal => [:white, :on_red]
  },
  :date => :blue,
  :logger => :cyan,
  :message => :magenta
)

Logging.appenders.stdout(
  'stdout',
  :layout => Logging.layouts.pattern(
    :pattern => '[%d] %-5l %c:%M %m\n',
    :color_scheme => 'bright'
  )
)

domain = "bindnameserver.org"
key = "./keys/nsupdatekey.private"
file = "filename"
foo = PushFile.new(domain, key, file)


