require 'open-uri'
require 'rexml/document'
require 'kconv'

xml_uris = [
            "http://www.nhk.or.jp/gogaku/french/kouza/listdataflv.xml",
            "http://www.nhk.or.jp/gogaku/english/training/listdataflv.xml",
            "http://www.nhk.or.jp/gogaku/english/business1/listdataflv.xml",
            "http://www.nhk.or.jp/gogaku/english/business2/listdataflv.xml"
           ]

flv_host = 'flv9.nhk.or.jp'
flv_app = 'flv9/_definst_/'
flv_service_prefix = 'flv:gogaku/streaming/flv/'
is_windows = RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|cygwin|bccwin/

rtmpdump = "rtmpdump.exe"

xml_uris.each do |xml_uri|
  open( xml_uri ) do |f|
    doc = REXML::Document.new( f )
    doc.elements.each( "musicdata/music" ) do |element|
      kouza = element.attributes["kouza"]
      hdate = element.attributes["hdate"]

      if is_windows
        kouza = kouza.kconv( Kconv::SJIS, Kconv::UTF8 )
        hdate = hdate.kconv( Kconv::SJIS, Kconv::UTF8 )
      end

      file = element.attributes["file"]
      if (! FileTest.exist?(file) || FileTest.size?(file) < 1000000)
        print "=== #{kouza} #{hdate} ===\n"
        url = "rtmp://#{flv_host}/#{flv_app}#{flv_service_prefix}" + file.sub(".flv", "")
        command = "#{rtmpdump} -r \"#{url}\" -o #{file}"
        system(command)
        count = 5
        while $? != 0 && count > 0
          system(command + " --resume" )
          count = count - 1
        end
      end
    end
  end
end
