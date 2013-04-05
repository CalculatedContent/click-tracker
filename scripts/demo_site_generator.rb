#!/usr/bin/env ruby
require 'rubygems'
require 'fileutils'
require 'trollop'
require 'logger'

@log = Logger.new($stderr)


def abort!(msg)
  @log.error msg
  exit(-1)
end



opts = Trollop::options do
  opt :bucket, "bucket name",  :short => "-b", :default => "cms-default-bucket-001"
  opt :file, "file",  :short => "-f", :default => "dump.rdb"
  opt :gzip, "gzip",  :short => "-Z", :default => true
end

# checks:
#   bucket name valid?
#   bucket exists, create?
#   logging
#   check return / checksum

begin

  bucket, file, gzip = opts[:bucket], opts[:file], opts[:gzip]
  
  abort! "file #{file} not found" unless File.exists?(file)
  abort! "bucket #{bucket} not found" if `s3cmd du s3://#{bucket}`.empty?  # string is blank

  timestamp = Time.new.gmtime.to_s.gsub(/ /,"X")
  s3_file = "#{file}.#{timestamp}"
  
  FileUtils.mv "#{file}" , s3_file

  if gzip then 
    `nice -n 19 gzip #{s3_file}`
    abort! "aborting: Could not gzip #{s3_file}" unless $?.exitstatus == 0
    s3_file = s3_file + ".gz"
  end

  md5_before = `md5 #{s3_file}`.split("=")[1].strip

  
  `s3cmd put #{s3_file} s3://#{bucket}`
  abort! "aborting: Could not upload #{s3_file} to S3" unless $?.exitstatus == 0

  info = `s3cmd info  s3://#{bucket}/#{s3_file}`
  #file_size_after = #  fix  ... info.split("\n")[1].split(":")[1].strip
  md5_after = info.split("\n")[4].gsub(/MD5 sum\:/,'').strip

  abort! "aborting: md5 checksum fails " if md5_after != md5_before

  FileUtils.rm "#{s3_file}"
  
  exit(0)
  
rescue => e
  abort! e.message
end
