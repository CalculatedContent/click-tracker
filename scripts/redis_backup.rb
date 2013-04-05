#!/usr/bin/env ruby
require 'rubygems'
require 'fileutils'
require 'trollop'
require 'logger'
require 'redis'

@log = Logger.new($stderr)


# 8-sep-2012 not used yet

def abort!(msg)
  @log.error msg
  exit
end

def wait_and_retry_on(sleep_time = 1, num_retries = 10,  &block)
   num = 0
   while (!block.call) and (num < num_retries)
     sleep(sleep_time)
     num += 1
  end
  return false if num >=  num_retries 
  return true
end


opts = Trollop::options do
  opt :bucket, "bucket name",  :short => "-b", :default => "cms-default-bucket-001"
  opt :file, "file",  :short => "-f", :default => "/var/redis/6379/dump.rdb"
end

begin

  bucket, file = opts[:bucket], opts[:file]

  @r = Redis.new
  abort! "bgsave is in progress" unless @r.info["bgsave_in_progress"].to_i == 0
  
  start_time = @r.lastsave
  @r.bgsave
  
  result = wait_and_retry_on(10,10) { @r.lastsave > start_time }
  abort! "bgsave failed" unless result

  
  cmd = "ruby ./backup.rb -f #{file} -b #{bucket}"
  system(cmd)
  @log.info cmd
  abort! "failed: #{cmd}" unless $?.exitstatus == 0

 
rescue => e
  abort! e.message
end

