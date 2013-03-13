require 'open-uri'
require 'rexml/document'
require 'rubygems'
require 'mp3info'

URL_PREFIX = "http://www.nhk.or.jp/gogaku"

#RANDOM_KEY = '0708VDUKWV57JA'
#RANDOM_KEY = '0624ML6UEAWJDR'
#RANDOM_KEY = '0532RQRK7HD79C'
#RANDOM_KEY = '0489YU92YUCBUE'
#RANDOM_KEY = '0473HBD7U85KNV'
#RANDOM_KEY = '0417CGN3L24HDL'
#RANDOM_KEY = '0383GUM3A7ERCK'
#RANDOM_KEY = '0233SSECSKHQTA'
#RANDOM_KEY = '0225GMVGLECXN9'
#RANDOM_KEY = '0158JU8Q6YFFG2'
#RANDOM_KEY = '0109BSNQVLFRF1'
#RANDOM_KEY = '0077PTLP2BX71C'

def get_random_key
  random_key = ""
  IO.popen(["gnash", "-r0", "-t5", "-v", "#{URL_PREFIX}/common/swf/streaming.swf"]) { |io|
    while log = io.gets
      if log =~ %r!#{URL_PREFIX}/common/swf/(.*)/listdataflv.xml!
        random_key = $1
        break
      end
    end
  } rescue false
  if random_key == ""
    puts "Failed to get random_key"
    exit 1
  else
    puts "random_key is #{random_key}"
    random_key
  end
end

RANDOM_KEY = get_random_key

class FlvFile
  attr_accessor :io

  def initialize io
    @io = io
  end

  def read size
    @io.read size
  end

  def read_ui24
    ("\000" + read(3)).unpack('N')[0]
  end

  def read_header
    signature, version, flags, offset = read(9).unpack("a3ccN")
    # puts "Header(#{signature}, #{version}, #{flags}, #{offset})"
  end

  def read_tag
    previous_tag_size = read(4).unpack('N')
    tag_type = read(1)

    return nil unless tag_type

    data_size = read_ui24
    time_stamp = read_ui24
    time_stamp_extended = read(1).unpack('c')
    stream_id = read_ui24
    bytes = read(data_size)

    case tag_type
    when "\x08"
      return [:AUDIO, bytes]
    when "\x09"
      return [:VIDEO, bytes]
    when "\x12"
      return [:SCRIPT, bytes]
    end
  end

  def extract filename, type
    read_header
    open(filename, 'wb') do |out|
      while (tag = read_tag)
        if tag[0] == type
          out.write tag[1][1..-1]
        end
      end
    end
  end

  def self.extract_audio input_filename, output_filename
    open(input_filename, 'rb') do |io|
      FlvFile.new(io).extract output_filename, :AUDIO
    end
  end

end

class RtmpServer
  FLV_HOST = 'flv9.nhk.or.jp'
  FLV_APP = 'flv9/_definst_/'
  FLV_SERVICE_PREFIX = "flv:gogaku/streaming/flv/#{RANDOM_KEY}/"
  RTMPDUMP = "rtmpdump"
  IS_WINDOWS = RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/

  def url file
    "rtmp://#{FLV_HOST}/#{FLV_APP}#{FLV_SERVICE_PREFIX}" + file.sub(".flv", "")
  end

  def command file
    "#{RTMPDUMP} -r \"#{url(file)}\" -o #{file}"
  end

  def get file
    system "#{command file}"
    $? == 0
  end

  def resume file
    system "#{command file} --resume"
    $? == 0
  end

  def download file
    get file and return true
    5.times do
      resume file and return true
    end
    false
  end

  def extract_mp3 input_filename, output_filename
    FlvFile.extract_audio input_filename, output_filename
  end

  def add_id3tag file, kouza, hdate, track
    Mp3Info.open(file, :encoding => 'utf-8') do |mp3|
      mp3.tag2.TCON = "Education"
      mp3.tag2.TALB = kouza
      mp3.tag2.TPE1 = "NHK"
      mp3.tag2.TPE2 = "NHK"
      mp3.tag2.TIT2 = hdate
      mp3.tag2.TYER = "2012"
      mp3.tag2.TRCK = track
    end
  end

  def process_flv file, kouza, hdate
    if FileTest.exist?(file) && FileTest.size?(file) >= 1000000
      puts "Skipped . . . #{file}"
    else
      puts "Downloading . . . #{file}"
      download file or return
      output_filename = file.sub('flv', 'mp3')
      begin
        extract_mp3 file, output_filename
        if kouza then
          if /^(\d\d)-[a-z0-9]+-[0-9]+-([0-9]+)/ =~ file then
            track = $2
          else
            tack = ''
          end
          add_id3tag output_filename, kouza, hdate, track
        end
      rescue => ex
        puts "***** FAILED (#{ex.message}) *****"
        File.delete output_filename
      end
    end
  end

  def process_xml_uri xml_uri
    open( xml_uri ) do |f|
      doc = REXML::Document.new( f )
      doc.elements.each( "musicdata/music" ) do |element|
        kouza = element.attributes["kouza"]
        hdate = element.attributes["hdate"]
        puts "=== #{kouza} #{hdate} ==="
        process_flv element.attributes["file"], kouza, hdate
      end
    end
  end

  def process_file file
    if file =~ /.xml$/
      process_xml_uri file
    elsif file =~ /.flv$/
      process_flv file, nil, nil
    else
      puts file
      open(file) do |f|
        f.each { |line| process_file line.chomp }
      end
    end
  end

end

def english program
  "#{URL_PREFIX}/english/#{program}/#{RANDOM_KEY}/listdataflv.xml"
end

def language language
  "#{URL_PREFIX}/#{language}/kouza/#{RANDOM_KEY}/listdataflv.xml"
end

def levelup language
  "#{URL_PREFIX}/#{language}/levelup/#{RANDOM_KEY}/listdataflv.xml"
end

xml_uris = [
            language("german"),
            language("spanish"),
            language("italian"),
            language("french"),
            language("chinese"),
            language("russian"),
            levelup("chinese"),
            # language("hangeul"),
            # english("training"),
            # english("business1"),
            # english("business2"),
            # english("kaiwa"),
           ]

server = RtmpServer.new
if ARGV.length > 0
  ARGV.each {|file| server.process_file file }
else
  xml_uris.each {|xml_uri| server.process_xml_uri xml_uri }
end
