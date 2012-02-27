#!/usr/bin/env ruby
require "pp"
require "logging"
require "digest/md5"
require "parallel"
require "dnsruby"
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
  Logging.appenders.stdout,
  Logging.appenders.file('get.log')
)

getname = "e8fkiy"

nameserver = "ns1.sendtodns.org"
domain = "sendtodns.org"
filedomain = getname + "." + domain
fileinfo = `dig @#{nameserver} TXT +short fileid.#{filedomain}`.split(",")
filename = fileinfo[0].to_s[1..-1]
startpart = fileinfo[1].split(".")[1].to_i
endpart = fileinfo[2].split(".")[1].to_i
md5sum = fileinfo[3][0...-2].to_s

partdomainlist = Hash.new


@logger.info "Filename: #{filename}"
@logger.info "Start: #{startpart}"
@logger.info "End: #{endpart}"
@logger.info "md5sum: #{md5sum}"

i = 0
until i == endpart do
    i = i + 1
    partfileinfodomain ="fileid.#{getname}.%03d.#{domain}" % i
    part = `dig @#{nameserver} TXT +short #{partfileinfodomain}`
    partcount = part.split(",")[1].to_i
    md5sum = part.split(",")[2][0...-2].to_s
    partdomainlist["#{partfileinfodomain}"] = [partcount, md5sum]
end

i = 0
x = 0
foo = ""
# Dnsruby::DNS.open(:nameserver=>["ns1.sendtodns.org"], :use_tcp=>["on"],:search=>["ns1.sendtodns.org"]) do |dns|
#   # dns.timeout = 60
#   pp dns.config
# Parallel.each(partdomainlist, :in_processes=>1) do |k,v|
#     @file_part = k.split(".")[2].to_s
#     partcount = v[0]
#     md5sum = v[1]
#     @logger.debug "Working on #{k} with #{partcount} parts and md5 #{md5sum}"
#     until i == partcount + 1 do
#       # digcommand = "dig @#{nameserver} TXT +short +vc #{i}.#{k.split(".")[1..-1].join(".")}" # | grep -v ^\\; | cut -d\\\" -f 2- | sed -e 's/" + "\" " + "\"" + "/\\'$\'\\n/g' | sed -E 's/^[0-9]+ //g' | sed 's/\\\"$//g'"
#       y = 0
#         foo << dns.getresource("#{i}.#{k.split(".")[1..-1].join(".")}", "TXT")
#     end
#     i = i + 1
#     y = y + 1
# #    end
#     file_part = File.new("#{getname}.get.#{k.split(".")[2].to_s}", "w")
#     file_part.write(foo)
#     file_part.close
#     i = 0
# end
# end
i = 0

Parallel.each(partdomainlist, :in_processes=>5) do |k,v|
  @file_part = k.split(".")[2].to_s
  partcount = v[0]
  md5sum = v[1]
  @logger.debug "Working on #{k} with #{partcount} parts and md5 #{md5sum}"
  until i == partcount + 1 do
    # print "#{i}.#{k.split(".")[1..-1].join(".")}\n"
    omg = Dnsruby::Resolver.new({:nameserver=>['ns1.sendtodns.org'], :use_tcp=>true}).query("#{i}.#{k.split(".")[1..-1].join(".")}", Dnsruby::Types.TXT).answer
    cutpoint = omg.to_s.index(' "') + 2
    foo << omg.to_s.slice(cutpoint..-3).to_s.gsub('" "', "\n").to_s + "\n"

    i = i + 1    
  end
  file_part = File.new("#{getname}.get.#{k.split(".")[2].to_s}", "w")
  file_part.write(foo)
  file_part.close
  i = 0
end



partdomainlist.each do |k,v|  
  @file_part = k.split(".")[1].to_s + ".get." + k.split(".")[2].to_s
  partcount = v[0]
  md5sum = v[1]
  downloaded_md5 = Digest::MD5.file(@file_part).to_s
  if downloaded_md5 == md5sum
    @logger.debug "#{@file_part} matched md5 sum"
  else
    @logger.error "#{@file_part} did not match md5 sum!"
    @logger.debug "Redownloading #{@file_part}"
    `rm #{@file_part}`
    until i == partcount + 1 do
      digcommand = "dig @#{nameserver} TXT +short +vc #{i}.#{k.split(".")[1..-1].join(".")}| grep -v ^\\; | cut -d\\\" -f 2- | sed -e 's/" + "\" " + "\"" + "/\\'$\'\\n/g' | sed -E 's/^[0-9]+ //g' | sed 's/\\\"$//g' >> #{getname}.get.#{k.split(".")[2].to_s}"
      `#{digcommand}`
      i = i + 1
    end
  end
end
  

`uudecode #{getname}.get.*`
`lxsplit -j #{getname}.001`
`mv #{getname} #{filename}`
`rm #{getname}.*`