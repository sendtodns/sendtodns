#!/usr/bin/env ruby
require "pp"
require "logging"
require "digest/md5"
require "parallel"
require "dnsruby"
require "benchmark"
require "progressbar"
include Dnsruby

Logging.color_scheme( 'bright',
  :levels => {
    :info  => :green,
    :warn  => :yellow,
    :error => :red,
    :fatal => [:white, :on_red]
  },
  :date => :blue,
  :logger => :cyan,
  :message => :magenta
)

Logging.appenders.stdout(
  'stdout',
  :layout => Logging.layouts.pattern(
    :pattern => '[%d] %-5l %c:%M %m\n',
    :color_scheme => 'bright'
  )
)

@logger = Logging.logger[self]
@logger.add_appenders(
  # Logging.appenders.stdout,
  Logging.appenders.file('get.log')
)

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

  def get(file_key, processes=30)
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
waa.get("fcynuv", 15)
# pp waa.lookup("fcynuv")
puts "Done"
# pp self.lookup("fcynuv")
# 
# # getname = "e8fkiy" # Elephants dream
# # getname = "4qefx5" # Ubuntu
# getname = "fcynuv" # Asterisk
# 
# nameserver = "ns1.sendtodns.org"
# domain = "sendtodns.org"
# filedomain = getname + "." + domain
# fileinfo = `dig @#{nameserver} TXT +short fileid.#{filedomain}`.split(",")
# filename = fileinfo[0].to_s[1..-1]
# startpart = fileinfo[1].split(".")[1].to_i
# endpart = fileinfo[2].split(".")[1].to_i
# md5sum = fileinfo[3][0...-2].to_s
# 
# partdomainlist = Hash.new
# 
# 
# @logger.info "Filename: #{filename}"
# @logger.info "Start: #{startpart}"
# @logger.info "End: #{endpart}"
# @logger.info "md5sum: #{md5sum}"
# 
# i = 0
# until i == endpart do
#     i = i + 1
#     partfileinfodomain ="fileid.#{getname}.%03d.#{domain}" % i
#     part = `dig @#{nameserver} TXT +short #{partfileinfodomain}`
#     partcount = part.split(",")[1].to_i
#     md5sum = part.split(",")[2][0...-2].to_s
#     partdomainlist["#{partfileinfodomain}"] = [partcount, md5sum]
#     @logger.debug "#{partfileinfodomain}, #{part}, #{partcount}, #{md5sum}, #{partdomainlist}"
# end
# 
# i = 0
# x = 0
# foo = ""
# i = 0
# process = 30
# totalpart = 0
# partdomainlist.each do |k,v|
#   totalpart += v[0].to_i
# end
# part = 0
# 
# batches = (endpart / process)
# @logger.debug "Batches with #{endpart} / #{process} = #{batches}"
# omg = ""
# foo = ""
# @x = 0

  
# 
# Parallel.each(partdomainlist, :in_processes => process) do |k,v|
#   @file_part = k.split(".")[2].to_s
#   partcount = v[0]
#   md5sum = v[1]
#   @logger.debug "Working on #{k} with #{partcount} parts and md5 #{md5sum} process count of #{process}"
#   time = Benchmark.realtime do
#     until i == partcount + 1 do
#       omg = Dnsruby::Resolver.new({:nameserver=>['199.193.245.49'], :use_tcp=>true, :query_timeout=>300}).query("#{i}.#{k.split(".")[1..-1].join(".")}", Dnsruby::Types.TXT).answer.to_s
#       cutpoint = omg.to_s.index("\t\"") + 2
#       foo << omg.to_s.slice(cutpoint..-3).to_s.gsub('" "', "\n") + "\n"
#       i += 1      
#     end
#     file_part = File.new("#{getname}.get.#{k.split(".")[2].to_s}", "w")
#     file_part.write(foo.split("\n").sort_by { |key| key.split(/(\d+)/).map { |v| v =~ /\d/ ? v.to_i : v } }.join("\n").to_s.gsub(/^\d+\s+/, "").to_s)
#     file_part.close
#     foo = ""
#     i = 0    
#   end
# end
# 
# 

  
  
  


# partdomainlist.each do |k,v|  
#   @file_part = k.split(".")[1].to_s + ".get." + k.split(".")[2].to_s
#   partcount = v[0]
#   md5sum = v[1]
#   downloaded_md5 = Digest::MD5.file(@file_part).to_s
#   if downloaded_md5 == md5sum
#     @logger.debug "#{@file_part} matched md5 sum"
#   else
#     @logger.error "#{@file_part} did not match md5 sum!"
#     @logger.debug "Redownloading #{@file_part}"
#     `rm #{@file_part}`
#     until i == partcount + 1 do
#       digcommand = "dig @#{nameserver} TXT +short +vc #{i}.#{k.split(".")[1..-1].join(".")}| grep -v ^\\; | cut -d\\\" -f 2- | sed -e 's/" + "\" " + "\"" + "/\\'$\'\\n/g' | sed -E 's/^[0-9]+ //g' | sed 's/\\\"$//g' >> #{getname}.get.#{k.split(".")[2].to_s}"
#       `#{digcommand}`
#       i = i + 1
#     end
#   end
# end
# 
# `uudecode #{getname}.get.*`
# `lxsplit -j #{getname}.001`
# `mv #{getname} #{filename}`
# `rm #{getname}.*`


