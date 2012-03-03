$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require "pp"
require "logging"
require "digest/md5"
require "parallel"
require "dnsruby"
require "benchmark"
require "progressbar"

# Encode
# require './std/encode/encode'
# require './std/encode/file'
require 'std/coder/decode'
# Receive
require 'std/receive/receive'

# Transmit
# require 'std/transmit/dns_update'
# require 'std/transmit/generate_records'
# require 'std/transmit/push_file'
# require 'std/transmit/sendtodns'

