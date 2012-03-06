module SendToDns
  module GenerateRecords

    def block(record, size)
      @logger.info "In block"
      iterator = 0
      block = Array.new
      tempblock = ""
      record.lines.each do |line|
        iterator = iterator + 1
        tempblock << line
        if iterator == size
          block << tempblock
          
          tempblock = ""
          iterator = 0
        end
      end
      block << tempblock
      @logger.debug "Leaving block #{block.size}"
      return block
    end
        
    def zoneblock(file,recordsize=40,blocksize=1)
      @logger.debug "In zoneblock working on #{file}"
      holder = Array.new
      interval = 0
      @logger.debug "Reading file with IO.read"
      filecontents = IO.read("#{@stage_directory}#{file}")
      @logger.debug "recordblock = block(file,recordsize)"
      recordblock = block(filecontents,recordsize)
      @logger.debug "#{recordblock.class}"
      recordblock.each do |i|
        record = ""
        i.each_line do |line|
          record = record + "\"#{line.gsub(/\s+/, ' ').lstrip.rstrip}\" "
        end
        
        
        record_update = record_fluff(interval,file,domain,record)
        
        holder << record_update

        interval = interval + 1
      end
        @logger.error "Returning an #{holder.class}"
        return holder
    end
    
    def record_fluff(interval,file,domain,record)
      record_update = "update add #{interval}.#{file}.#{domain}. 604800 A 192.168.1.100\n" +
                      "update add #{interval}.#{file}.#{domain}. 604800 TXT #{record}"
      #puts record_update

    end

    def nsupdate(updateblock)
      zonevalue = "server #{@nameserver}\n" + 
                  "zone #{@domain}\n" +
                  "#{updateblock}\n" +
                  "show\n" +
                  "send\n" 
      return zonevalue
    end
    
    def send_block(blocklength)
          filelist.each do |file|
          filename = file.split("/").last
          @logger.debug "Working on #{filename} with md5 #{@md5list[filename]}"
          block = self.zoneblock(filename)
          block << record_fluff("fileid", @randomname, domain, "\"#{@file},#{filelist.first.split("/").last},#{filelist.last.split("/").last},#{@main_md5}\"")
          block << record_fluff("fileid", filename, domain, "\"#{filename},#{block.length.to_i - 2},#{@md5list[filename]}\"")
          while block.length > 0
            if block.slice(blocklength) != nil
              cut = block.slice!(0..blocklength)
            else
              cut = block.slice!(0..-1)
            end
            # Resque.enqueue(DNSUpdate, @key, nsupdate(cut.join("\n")))
            #result = Parallel.map(['a', 'b', 'c']) do |one_letter|
              DNSUpdate.perform(@key, nsupdate(cut.join("\n")))
            #end
          end
        end
    end
    
  end
end
