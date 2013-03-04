#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'redis'
require 'json'
require 'uri'
require 'htmlentities'

configure do
  REDIS = Redis.new
#  REDIS['domain'] = 
  DOMAIN = "ec2-184-169-148-23.us-west-1.compute.amazonaws.com"
end


get '/hello' do
  REDIS['hello']='hi ya from redis'
  REDIS['hello']
end

# matches "GET /hello/foo" and "GET /hello/bar"
# params[:name] is 'foo' or 'bar'
get '/hello/:name' do
    @name = params[:name]
    erb :hello
end

get "/" do
  "recommender working"
end

get '/test_recos' do
   @recos =  recommendations(REDIS["url:1"])
   erb :reco
end

get '/test_recos_as_json' do
   recommendations(REDIS["url:1"]).to_json
end

get '/test_url' do
  url = params[:url]
  url_hp = begin
    url_host_path(url)
  rescue => e
    e
  end
  
  [url,url_hp].to_s
end



# def get_redis(request)
  # REDIS.select 0
  # REDIS.select REDIS["host_db:#{request.host}"]
  # REDIS
# end

get '/track.js' do
  @base_url = "http://#{DOMAIN}"  
  erb :track
end

get '/record' do
  log = params.to_json
  REDIS.lpush('log',log)
  
  referer = params[:referer]
  url = params[:url]
  title = params[:title]

  return "" unless valid_url(referer)
 
  uid = add_url(url)
  rid = add_url(referer)
  
  update_reco(uid,rid,title)
  return ""
end

get '/recommendations' do
   url =  request.referer
   return [].to_json  unless valid_url(url)
   @recos = recommendations(url)
   erb :reco
end



get '/recommendations_as_json' do
   url =  request.referer
   return [].to_json  unless valid_url(url)
   recos = recommendations(url)
   recos.to_json
end



get '/top_n' do
   num = params[:num] || 5
   @top_n = top_n(num)
   erb :top_n
end



get '/top_n_as_json' do
   num = params[:num] || 5
   top_n(5).to_json
end


# TODO:   check u
def valid_url(url)
  return false if url.nil? or url.empty?
 # return false unless url =~ /.*#{DOMAIN}.*/
  return true  
end  

def url_host_path(url)
  coder = HTMLEntities.new
  uri = URI(coder.decode(url))
  "#{uri.host}#{uri.path}"  
end


def add_url(url)
  url = url_host_path(url)
  # ignore url if domain is not local
  uid = REDIS["id:#{url}"]  
  if uid.nil? or uid.empty? then 
     REDIS.sadd('urls', url)
     uid = REDIS.scard('urls')  
     REDIS.pipelined do
       REDIS["id:#{url}"] = uid
       REDIS["url:#{uid}"] = url      
     end
  end
  return uid
  
end

def update_reco(uid,rid, title=nil)
  REDIS.pipelined do
    REDIS["title:#{uid}"] = title  unless title.nil?  
    REDIS.zincrby "recos:#{rid}", 1, uid  
    REDIS.zincrby "counts", 1 , uid
    # latest
    # trending
  end
end

def top_n(num=5)
   results = REDIS.zrevrangebyscore("counts", '+inf', '-inf', {:withscores => true} )
   
   recos = results[0...num].map do |x| uid,score = x[0],x[1]
     { :title=>REDIS["title:#{uid}"], :url=>REDIS["url:#{uid}"], :score=>score }
   end
   
   return recos
end
  
  
   # if unknow url, return topN random URLS
def recommendations(url,num=5)
   url = url_host_path(url)
   uid = REDIS["id:#{url}"]
   results = REDIS.zrevrangebyscore("recos:#{uid}", '+inf', '-inf', {:withscores => true} )
   
   recos = results[0...num].map do |x| uid,score = x[0],x[1]
     { :title=>REDIS["title:#{uid}"], :url=>REDIS["url:#{uid}"], :score=>score }
   end
   
   return recos
end
