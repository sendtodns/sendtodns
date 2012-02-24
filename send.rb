#!/usr/bin/env ruby
require "./lib/send_to_dns.rb"
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

domain = "ns1.example.org"
key = "./keys/private.key"
file = "asterisk-1.8.9.0.tar.gz"
foo = PushFile.new(domain, key, file)


