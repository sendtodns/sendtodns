class DNSUpdate
  @queue = :sendtodns

  def self.perform(records)
    IO.popen('nsupdate -v -k ./keys/nsupdatekey.private', 'w') {|io| io.puts records}
  end
end
