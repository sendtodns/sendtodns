require "digest/md5"
require "dir"
require "FileUtils"

module SendToDns
  module File
    extend self
    attr_accessor :stage_directory

    def randomname(length=6)
      chars = ("a".."z").to_a + ("a".."z").to_a + ("0".."9").to_a
      randomname = ""
      1.upto(length) { |i| randomname << chars[rand(chars.size-1)] }
      return randomname
    end  

    def maketemp(tempdir="/tmp/sendtodns")
      @stage_directory = "#{tempdir}/#{randomname}/"
      @logger.debug "Making staging area #{@stage_directory}"
      FileUtils.mkdir_p(@stage_directory)
    end
  
    def copyfile(file=@file)
      @logger.debug "Copying ./files/#{file} into #{@stage_directory}"
      FileUtils.cp("./files/#{file}", @stage_directory)
    end
  
    def renamefile(file=@file)
      @logger.debug "Renaming #{file} to #{randomname}"
      puts "#{@stage_directory}/#{file}","#{@stage_directory}/#{randomname}"
      FileUtils.mv("#{@stage_directory}/#{file}","#{@stage_directory}/#{randomname}")
    end
  
    def splitfile(file=@file, size="1m")
      @logger.debug "Splitting #{randomname} into #{size} chunks"
      `#{changedir}; lxsplit -s #{randomname} #{size}`
    end

    def cleanfile()
      #Not sure how this will work given that the randomname would change with each call
      @logger.debug "Cleaning file move"
      FileUtils.rm("#{@stage_directory}/#{randomname}")
    end
  
    def changedir()
      "cd #{@stage_directory}"
    end
    
    def uuencode()
      filenum = 0
      `#{changedir}; rm #{randomname}`;
      pp filelist
      filelist.each do |i|
        filename = i.split("/").last
        puts filename
        filenum += 1
        puts "i: #{i}"
        command = "#{changedir}; uuencode -m -o #{i}.uu #{i} #{filename}; rm #{filename}; mv #{filename}.uu #{filename}"
        puts command
        `#{command}`
        @logger.debug "#{command}"
        
      end
    end
    
    def generate_md5(file)
      `#{changedir}`
      md5sum = Digest::MD5.file("#{@stage_directory}/#{file}")
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
      puts "maketemp"
      maketemp
      puts "copyfile"
      copyfile
      puts "generate_md5"
      @main_md5 = generate_md5(file)
      puts "renamefile"
      renamefile
      puts "splitfile"
      splitfile
      puts "uuencode"
      uuencode
      puts "md5list"
      md5list
      puts "numberfiles"
      numberfiles
      puts "filelist"
      filelist
    end
    
    def md5list()
      @md5list = Hash.new
      filelist.each do |i|
        filename = i.split("/").last
        @md5list[filename] = generate_md5(filename)
      end
      return @md5list
    end
    
    def filelist()
      Dir.glob("#{@stage_directory}*")
    end
  end
end
