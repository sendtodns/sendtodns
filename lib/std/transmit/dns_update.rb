class DNSUpdate
  
  @queue = :sendtodns

  def self.perform(key,records)
    IO.popen("nsupdate -v -k #{key}", 'w') do |io| 
      io.puts records
      #puts records
      #sleep 1
    end
  end
end
