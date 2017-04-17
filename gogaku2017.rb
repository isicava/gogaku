#!bundle exec ruby
# -*- coding: utf-8 -*-
require 'open-uri'
require 'openssl'
require 'rexml/document'
require 'rubygems'
require 'taglib'
require 'date'

OP_NO_TLSv1_2 = 0x08000000
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OP_NO_TLSv1_2

def make_path file, isLimited=false
  if isLimited
    "https://nhk-vh.akamaihd.net/i/gogaku-stream/r/#{file}/master.m3u8"
  else
    "https://nhk-vh.akamaihd.net/i/gogaku-stream/mp4/#{file}/master.m3u8"
  end
end

def listdataxml(lang, course)
  "https://www2.nhk.or.jp/gogaku/st/xml/#{lang}/#{course}/listdataflv.xml"
end

def download path, outfile
  system "ffmpeg -i #{path} -absf aac_adtstoasc -acodec copy #{outfile}"
end

def proc_xml url, isLimited=false
  # puts url
  open(url) do |f|
    doc = REXML::Document.new(f)
    doc.elements.to_a("musicdata/music").last(5).each do |e|
      title = e.attributes["title"]
      hdate = e.attributes["hdate"]
      kouza = e.attributes["kouza"]
      code = e.attributes["code"]
      file = e.attributes["file"]
      nendo = e.attributes["nendo"]
      pgcode = e.attributes["pgcode"]
      path = make_path(file, isLimited)
      outfile = "data/" + file.sub("mp4", "m4a")
      if FileTest.exist?(outfile) && FileTest.size?(outfile) >= 1000000
        puts "Skipped . . . #{outfile}"
      else
        puts "Downloading . . . #{outfile}"
        download path, outfile
        set_title outfile, title, hdate, kouza, code, nendo
      end
    end
  end
end

def proc_url_list(list, isLimited = false)
  list.each do |url|
    proc_xml url, isLimited
  end
end

def kouza(lang)
  listdataxml(lang, "kouza")
end

def kouza2(lang)
  listdataxml(lang, "kouza2")
end

def chinese(course)
  listdataxml("chinese", course)
end

def hangeul(course)
  listdataxml("hangeul", course)
end

def english(course)
  listdataxml("english", course)
end

def set_title file, title, hdate, kouza, code, nendo
  TagLib::MP4::File.open(file) do |mp4|
    tag = mp4.tag
    tag.genre = "Education"
    tag.artist = 'NHK'
    tag.album = title + nendo
    tag.title = hdate
    tag.year = nendo.to_i
    tag.track = code.to_i % 1000
    tag.comment = code
    mp4.save
  end
end


list = [
  # english("basic1"),
  # english("basic2"),
  # english("basic3"),
  # english("kaiwa"),
  # english("enjoy"),
  # english("timetrial"),
  english("gendai"),
  english("business1"),
  english("business2"),
  english("vr-radio"),

  chinese("kouza"),
  chinese("levelup"),
  chinese("omotenashi"),

  hangeul("kouza"),
  hangeul("levelup"),

  kouza("german"),
  kouza2("german"),
  kouza("french"),
  kouza2("french"),
  kouza("italian"),
  kouza2("italian"),
  kouza("spanish"),
  kouza2("spanish"),
  kouza("russian"),
  kouza2("russian"),
]

limited_list = [
  english("3month"),
]

proc_url_list list
proc_url_list limited_list, true
