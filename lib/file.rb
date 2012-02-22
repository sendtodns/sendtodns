require "digest/md5"

module SendToDNS
  module File
    extend self
    def randomname(length=6)
      chars = ("a".."z").to_a + ("a".."z").to_a + ("0".."9").to_a
      randomname = ""
      1.upto(length) { |i| randomname << chars[rand(chars.size-1)] }
      return randomname
    end  

    def maketemp(tempdir="/tmp/sendtodns")
      @stagedirectory = "#{tempdir}/#{randomname}/"
      @logger.debug "Making staging area #{@stagedirectory}"
      `mkdir -p #{@stagedirectory}`
      return @stagedirectory
    end
  
    def copyfile(file=@file)
      @logger.debug "Copying ./files/#{file} into #{@stagedirectory}"
      `cp ./files/#{file} #{@stagedirectory}`
    end
  
    def renamefile(file=@file)
      @logger.debug "Renaming #{file} to #{randomname}"
      `#{changedir}; mv #{file} #{randomname}`
    end
  
    def splitfile(file=@file, size="1m")
      @logger.debug "Splitting #{randomname} into #{size} chunks"
      `#{changedir}; lxsplit -s #{randomname} #{size}`
    end

    def cleanfile()
      @logger.debug "Cleaning file move"
      `#{changedir}; rm #{randomname}.???`
    end
  
    def changedir()
      "cd #{@stagedirectory}"
    end
    
    def uuencode()
      # @encodedfile = Hash.new
      # @encodedfile[ :"#{file}" ] = `uuencode -m #{@file} #{@file}`.split("\n")
      `#{changedir}; rm #{randomname}`; 
      filelist.each do |i|
        command = "#{changedir}; mkdir -p tmp; uuencode -m -o ./tmp/#{i} #{i} #{i}; mv tmp/* ./; rmdir tmp"
        `#{command}`
        @logger.debug "#{command}"
        
      end
      # return @encodedfile
    end
    
    def generate_md5(file)
      `#{changedir}`
      md5sum = Digest::MD5.file("#{@stagedirectory}/#{file}")
      @logger.debug "#{file} md5: #{md5sum}"
      return md5sum
    end
          
    def numberfiles()
      filelist.each do |i|
        `#{changedir}; mv #{i} #{i}.tmp; nl #{i}.tmp > #{i}; rm #{i}.tmp`
        @logger.debug "#{changedir}; mv #{i} #{i}.tmp; nl #{i}.tmp > #{i}; rm #{i}.tmp"
      end
    end
    
    def stage(file=@file)
      maketemp
      copyfile
      @main_md5 = generate_md5(file)
      renamefile
      splitfile
      # cleanfile
      uuencode
      md5list
      numberfiles
      # cleanfile
      filelist
      # sleep 100
    end
    
    def md5list()
      @md5list = Hash.new
      filelist.each do |i|
        @md5list[i] = generate_md5(i)
      end
      return @md5list
    end
    
    def filelist()
      @filelist = `ls -1 #{@stagedirectory}`.split("\n")
      return @filelist
    end
  end
end
