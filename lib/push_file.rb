class PushFile
  attr_accessor :domain, :key, :file, :randomname

  include SendToDns
  include SendToDns::File
  include SendToDns::GenerateRecords
  
  
  def initialize(domain, key, file)
    @domain, @key, @file = domain, key, file    
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

