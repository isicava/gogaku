#!/usr/bin/env ruby

require 'rubygems'
require 'id3lib'
require 'kconv'

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

  def read_tags
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
    tag = ID3Lib::Tag.new(output_filename)
    tag.delete_if { |frame| [:TDRC, :TCON, :TIT2, :TALB, :TRCK].include?(frame[:id]) }
    # tag << { :id => :TDRC, :text =>"2009", :textenc => 0 }
    tag << { :id => :TCON, :text =>"Education", :textenc => 0 }
    tag << { :id => :TALB, :text => "‚Ü‚¢‚É‚¿ƒhƒCƒcŒê".kconv(Kconv::UTF16, Kconv::SJIS), :textenc => 1 }
    tag << { :id => :TIT2, :text =>"Deutch #1", :textenc => 0 }
    tag << { :id => :TRCK, :text => track = '1' }
    tag.update!
  end

end

FlvFile.extract_audio  ARGV[0], ARGV[1]
