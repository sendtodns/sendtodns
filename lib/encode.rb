module SendToDNS
  module Encode
    extend self
    
    def uuencode(file)
      `uuencode -m -o #{@file}.uu #{@file} #{@file}`
    end
         
  end
end


