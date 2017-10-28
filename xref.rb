# get the name of the executable we are checking
if (ARGV.length == 0)
   abort("must provide a path to an executable as an argument!") 
end
path = ARGV[0]

puts "executable: " + path
# need a more precise regex that only captures main instructions, this is all just for figuring things out
regex = /^[ \t]*([0-9a-f]{6}):[ \t]*((?: ?[0-9a-f]{2})+)[ \t]*([a-z]+) *([a-z0-9%,$@\(\) <>]+)/
asmarray = `~cs254/bin/objdump -d hello`.scan(regex)
puts asmarray
