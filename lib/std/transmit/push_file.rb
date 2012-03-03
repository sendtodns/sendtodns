class PushFile
  attr_accessor :domain, :key, :file, :randomname

  include SendToDns
  include SendToDns::File
  include SendToDns::GenerateRecords
  
  
  def initialize(domain, nameserver, key, file)
    @domain, @nameserver, @key, @file = domain, nameserver, key, file    
    @randomname = SendToDns::File::randomname
    @logger = Logging.logger[self]
    @logger.add_appenders(
      Logging.appenders.stdout,
      Logging.appenders.file('development.log')
    )
    self.stage
    self.send_block(5)
        
  end


  
end

