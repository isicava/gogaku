#!ruby
require 'open-uri'
require 'openssl'
require 'rexml/document'
require 'rubygems'

OP_NO_TLSv1_2 = 0x08000000
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OP_NO_TLSv1_2

def connectDirectory
  "0158JU8Q6YFFG2"
end

def make_path file
  akmai='https://nhkmovs-i.akamaihd.net/i/gogaku'
  akmai_m3u8='master.m3u8'
  akamai_streaming=['streaming/mp4', connectDirectory].join('/')
  type = akamai_streaming
  [akmai, type, file, akmai_m3u8].join('/')
end

def proc_xml url
  open(url) do |f|
    doc = REXML::Document.new(f)
    doc.elements.each("musicdata/music") do |e|
      kouza = e.attributes["kouza"]
      hdata = e.attributes["hdata"]
      file = e.attributes["file"]
      path = make_path(file)
      system "ffmpeg -i #{path} -absf aac_adtstoasc -acodec copy #{file}"
    end
  end
end

def proc_url_list(list)
  list.each do |url|
    proc_xml url
  end
end

def listdataxml(lang, course)
  ["https://cgi2.nhk.or.jp/gogaku", lang, course, connectDirectory,
   "listdataflv.xml"].join("/")
end

def language(lang)
  listdataxml(lang, "kouza")
end

def english(course)
  listdataxml("english", course)
end

list = [
  language("german"),
  language("french"),
  language("italian"),
  language("spanish"),
  language("russian"),
  language("chinese"),
  language("hangeul"),
  english("business1"),
  english("business2"),
]

list2 = [ english("business1") ]
proc_url_list list2


