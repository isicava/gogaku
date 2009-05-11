require 'kconv'

s = "Š¿Žš"
puts s
puts s.length
puts Kconv.guess(s)

