#!bundle exec ruby
# -*- coding: utf-8 -*-
require 'open-uri'
require 'openssl'
require 'rexml/document'
require 'rubygems'
require 'taglib'
require 'date'
require 'net/http'
require 'uri'
require 'json'

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

def listdatajson(code)
  "https://www.nhk.or.jp/radioondemand/json/#{code}/bangumi_#{code}_01.json"
end

def download path, outfile
  #ffmpeg = "/usr/local/Cellar/ffmpeg/3.3.1/bin/ffmpeg"
  ffmpeg = "ffmpeg -loglevel warning"
  system "#{ffmpeg} -i #{path} -absf aac_adtstoasc -acodec copy \"#{outfile}\""
end

def proc_xml url, isLimited=false
  # puts url
  URI.open(url) do |f|
    doc = REXML::Document.new(f)
    doc.elements.to_a("musicdata/music").last(10).each do |e|
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

def proc_json url, isLimited=false
  # puts url
  uri = URI.parse(url)
  json = Net::HTTP.get(uri)
  doc = JSON.parse(json)
  main = doc["main"]
  program_name = main["program_name"]
  nendo = "2021"
  main["detail_list"].each do |list|
    list["file_list"].each do |e|
      title = e["file_title"]
      onair_date = e["onair_date"]
      _, hdate = */\A(\d+月\d+日)/.match(onair_date)
      kouza = program_name
      file_id = e["file_id"]
      path = e["file_name"]
      # pgcode = e.attributes["pgcode"]
      file = program_name.gsub(/\s+/, "") + "-" + hdate + ".m4a"
      outfile = "data/" + file
      if FileTest.exist?(outfile) && FileTest.size?(outfile) >= 1000000
        puts "Skipped . . . #{outfile}"
      else
        puts "Downloading . . . #{outfile}"
        download path, outfile
        set_title outfile, program_name, hdate, kouza, file_id, nendo
      end
    end
  end
end

def proc_url_list(list, isLimited = false)
  list.each do |url|
    if url.end_with? 'json'
      proc_json url
    else
      proc_xml url, isLimited
    end
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
  # english("basic0"),
  # english("basic1"),
  # english("basic2"),
  # english("basic3"),
  # english("kaiwa"),
  # # english("enjoy"),
  # # english("timetrial"),
  # english("gendai"),
  # english("business1"),
  # english("business2"),
  # english("gakusyu"),
  # english("vr-radio"),
  listdatajson("6809"), # ビジネス英語
  listdatajson("0916"), # 英会話
  listdatajson("2331"), # 英会話タイムトライアル
  listdatajson("4407"), # 高校生からはじめる現代英語
  listdatajson("3064"), # エンジョイ・シンプル・イングリッシュ
  listdatajson("4121"), # ボキャブライダー
  listdatajson("4794"), # 遠山顕の英会話楽習
  listdatajson("4812"), # ニュースで英語術

  #chinese("kouza"),
  listdatajson("0915"), # まいにち中国語
  #chinese("levelup"),
  #chinese("omotenashi"),
  listdatajson("6581"), # ステップアップ中国語

  #hangeul("kouza"),
  listdatajson("0951"), # まいにちハングル講座
  #hangeul("levelup"),
  listdatajson("6810"), # ステップアップハングル講座

  # kouza("german"),
  # kouza2("german"),
  # kouza("french"),
  # kouza2("french"),
  # kouza("italian"),
  # kouza2("italian"),
  # kouza("spanish"),
  # kouza2("spanish"),
  # kouza("russian"),
  # kouza2("russian"),
  listdatajson("0946"), # まいにちイタリア語 入門編
  listdatajson("4411"), # まいにちイタリア語 応用編
  listdatajson("0943"), # まいにちドイツ語 入門編
  listdatajson("4410"), # まいにちドイツ語 応用編
  listdatajson("0953"), # まいにちフランス語 入門編
  listdatajson("4412"), # まいにちフランス語 応用編
  listdatajson("0948"), # まいにちスペイン語 入門編
  listdatajson("4413"), # まいにちスペイン語 応用編
  listdatajson("0956"), # まいにちロシア語 入門編
  listdatajson("4414"), # まいにちロシア語 応用編
  listdatajson("0937"), # アラビア語講座
  listdatajson("1893"), # ポルトガル語入門

#  english("3month"),
]

xlist = [ listdatajson("6581") ]

limited_list = [
#  english("3month"),
]


if ARGV.length > 0
   proc_url_list [ listdataxml(ARGV[0], ARGV[1]) ]
else
   proc_url_list list
   proc_url_list limited_list, true
end
