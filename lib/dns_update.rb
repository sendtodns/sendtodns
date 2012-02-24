class DNSUpdate
  
  @queue = :sendtodns

  def self.perform(key,records)
    IO.popen("nsupdate -v -k #{key}", 'w') {|io| io.puts records}
  end
end
