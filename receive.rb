#!/usr/bin/env ruby
require "pp"
require "logging"
require "digest/md5"
require "parallel"
require "dnsruby"
require "benchmark"
require "progressbar"
include Dnsruby

class Std
  attr_accessor :file_name, :file_start, :file_end, :file_md5, :part_list

  def initialize(nameserver='199.193.245.49', domain='sendtodns.org')
    @nameserver, @domain = nameserver, domain    
  end

  def lookup(file_key)
    file_query_domain = "fileid.#{file_key}.#{@domain}"
    
    file_info = Dnsruby::Resolver.new({:nameserver=>@nameserver, :use_tcp=>true, :query_timeout=>300}).query(file_query_domain, Dnsruby::Types.TXT).answer[0].data
    # pp file_info
    # "[fileid.fcynuv.sendtodns.org.\t14400\tIN\tTXT\t\"asterisk-1.8.9.0.tar.gz,fcynuv.001,fcynuv.024,9f0e369aa29437d559368bd385cec718\"]"
    self.file_name = file_info.split(',')[0]
    self.file_start = file_info.split(',')[1].split('.')[1].to_i
    self.file_end = file_info.split(',')[2].split('.')[1].to_i
    self.file_md5 = file_info.split(',')[3]
    self.part_list = Hash.new

    file_end.times do |i|
      i += 1
      part_query_domain = "fileid.#{file_key}.%03d.#{@domain}" % i
      
      part_info = Dnsruby::Resolver.new({:nameserver=>@nameserver, :use_tcp=>true, :query_timeout=>300}).query(part_query_domain, Dnsruby::Types.TXT).answer[0].data
      
      part_count = part_info.split(",")[1].to_i
      part_md5sum = part_info.split(",")[2][0...-1].to_s
      self.part_list[part_query_domain] = [part_count, part_md5sum]
      # @logger.debug "#{partfileinfodomain}, #{part}, #{partcount}, #{md5sum}, #{partdomainlist}"
    end
  end

  def receive(file_key, processes=30)
    part = ""
    i = 0
    
    self.lookup(file_key)


    Parallel.each(self.part_list, :in_processes => processes) do |k,v|
      puts "#{k}, #{v}"
      part_number = k.split(".")[2].to_s
      part_count = v[0]
      part_md5sum = v[1]
      until i == part_count + 1 do
        part_query_domain = "#{i}.#{k.split(".")[1..-1].join(".")}"
        part_info = Dnsruby::Resolver.new({:nameserver=>@nameserver, :use_tcp=>true, :query_timeout=>300}).query(part_query_domain, Dnsruby::Types.TXT).answer.to_s
        part_cut = part_info.to_s.index("\t\"") + 2
        part << part_info.to_s.slice(part_cut..-3).to_s.gsub('" "', "\n") + "\n"
        i += 1      
      end
      file_part = File.new("#{file_key}.get.#{k.split(".")[2].to_s}", "w")
      file_part.write(part.split("\n").sort_by { |key| key.split(/(\d+)/).map { |v| v =~ /\d/ ? v.to_i : v } }.join("\n").to_s.gsub(/^\d+\s+/, "").to_s)
      file_part.close
      file = ""
      i = 0    
    end

  end
end

waa = Std.new
waa.receive("fcynuv", 15)
# pp waa.lookup("fcynuv")
puts "Done"


