require "./lib/file.rb"
require "./lib/generaterecords.rb"
require "pp"

module SendToDNS
  extend self
  
  include SendToDNS::File
  include SendToDNS::GenerateRecords
end

class PushFile
  attr_accessor :domain, :key, :file, :randomname

  include SendToDNS
  # include SendToDNS::File
  
  
  def initialize(domain, key, file)
    @domain, @key, @file = domain, key, file    
    @randomname = SendToDNS::File::randomname
    @logger = Logging.logger[self]
    @logger.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('development.log')
    )
    self.stage
    self.send_block(5)
        
  end


  
end

class DNSUpdate
  @queue = :sendtodns

  def self.perform(records)
    IO.popen('nsupdate -v -k ./keys/nsupdatekey.private', 'w') {|io| io.puts records}
    # sleep 0.2
    # puts records
  end
end
