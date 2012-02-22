module SendToDNS
  module Encode
    extend self
    
    def uuencode(file)
      # @encodedfile = Hash.new
      # @encodedfile[ :"#{file}" ] = `uuencode -m #{@file} #{@file}`.split("\n")
      `uuencode -m -o #{@file}.uu #{@file} #{@file}`
      # return @encodedfile
    end
         
  end
end


