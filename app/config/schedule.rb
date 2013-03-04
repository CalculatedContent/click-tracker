pwd = File.expand_path File.dirname(__FILE__)
log_dir = File.expand_path "#{pwd}/../logs"
scripts_dir = File.expand_path "#{pwd}/../scripts"

redis_port = 6379
redis_dump_file = "/var/redis/#{redis_port}/dump.rdb"
s3_bucket = "s3://ta-bucket"

every 1.day, :at => '4:30 am' do
   command "ruby #{scripts_dir}/backup.rb -f #{redis_dump_file} -b #{s3_bucket}", :output => "#{log_dir}/whenever.log"
end

