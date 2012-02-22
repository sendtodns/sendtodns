require "./lib/file.rb"
require "./lib/generate_records.rb"
require "./lib/push_file"
require "./lib/dns_update"
require "pp"

module SendToDns
  extend self
  
  include SendToDns::File
  include SendToDns::GenerateRecords
end
