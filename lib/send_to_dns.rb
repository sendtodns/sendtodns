require "./lib/file"
require "./lib/generate_records"
require "./lib/push_file"
require "./lib/dns_update"
require "pp"

module SendToDns
  extend self
  
  include SendToDns::File
  include SendToDns::GenerateRecords
end
