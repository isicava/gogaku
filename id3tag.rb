require 'rubygems'
require 'id3lib'
require 'kconv'

tag = ID3Lib::Tag.new('x.mp3')
tag.delete_if { |frame| [:TDRC, :TCON, :TIT2, :TALB, :TRCK].include?(frame[:id]) }
# tag << { :id => :TDRC, :text =>"2009", :textenc => 0 }
tag << { :id => :TCON, :text =>"Education", :textenc => 0 }
tag << { :id => :TALB, :text => "‚Ü‚¢‚É‚¿ƒhƒCƒcŒê".kconv(Kconv::UTF16, Kconv::SJIS), :textenc => 1 }
tag << { :id => :TIT2, :text =>"Deutch #1", :textenc => 0 }
tag << { :id => :TRCK, :text => track = '1' }
tag.update!

