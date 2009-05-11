require 'rubygems'
require 'id3lib'
require 'kconv'

def put_tag tag, size, flags, bytes
  print "   "
  case tag
  when "RVA2"
    pos = bytes.index(0)
    id = bytes[0, pos]
    channel, volume_adjustment, peak = bytes[pos+1 .. -1].unpack("ccxc")
    puts "RVA2   : ID=\"#{id}\", ch=#{channel}, v=#{volume_adjustment}, peak=#{peak}"
  when /^T/
    code = bytes[0]
    bytes = bytes[1..-1]
    case code
    when 0
      puts "#{tag}(A): #{bytes}"
    when 1
      text = bytes.kconv(Kconv::SJIS, Kconv::UTF16)
      puts "#{tag}(U): #{text}"
    when 2
      text = bytes.kconv(Kconv::SJIS, Kconv::UTF16)
      puts "#{tag}(UBE): #{text}"
    when 3
      text = bytes.kconv(Kconv::SJIS, Kconv::UTF8)
      puts "#{tag}(8): #{text}"
    else
      print "#{tag}(?): #{bytes}"
    end
  else
    puts "#{tag}, #{size}, #{flags}"
  end
end

dir="."
Dir.entries(dir).each do |filename|
  if filename =~ /\.mp3$/ then
    print filename, " "
    open(dir+"/" + filename, "rb") do |f|
      bytes = f.read(10)
      if (bytes[0..2] == "ID3") then
        h = bytes.unpack("a3CCCN")
        version = h[1]
        revision = h[2]
        flags = h[3]
        size = h[4]
        puts "ID3 V=#{version}.#{revision} flags=#{flags} size=#{size}"
        total_size = size - 10
        if flags & 0x40 != 0 then
          puts "With Extended Header"
          size = f.read(10).unpack("N")[0]
          f.seek size-4, IO::SEEK_CUR
        end
        while  total_size > 0 do
          if version == 2 then
            tag, s, t, u = f.read(6).unpack("a3c3")
            size = s * 256 * 256 + t *256 + u
          else
            tag, size, flags = f.read(10).unpack("a4Nn")
          end
            break if size == 0 || tag[0..3] == "3DI"
            bytes = f.read(size)
            put_tag tag, size, flags, bytes
            total_size = total_size - size
          end
      else
        puts "NO ID3 Tag"
      end
    end
  end
end

