require 'kconv'

s = "����"
puts s
puts s.length
puts Kconv.guess(s)

