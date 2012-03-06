require "./lib/std/encode/file"
require "./lib/std/transmit/generate_records"
require "./lib/std/transmit/push_file"
require "./lib/std/transmit/dns_update"
require "pp"

module SendToDns
  extend self
  
  include SendToDns::File
  include SendToDns::GenerateRecords
end
