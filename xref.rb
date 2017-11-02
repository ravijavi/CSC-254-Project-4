# get the name of the executable we are checking
if (ARGV.length == 0)
   abort("must provide a path to an executable as an argument!") 
end
path = ARGV[0]

puts "executable: " + path + "\n\n"
# need a more precise regex that only captures main instructions, this is all just for figuring things out
regex_obj = /^[ \t]*([0-9a-f]{6}):[ \t]*((?: ?[0-9a-f]{2})+)[ \t]*([a-z]+) *([a-zA-Z0-9%,$@\(\) <>_\+\*\#\.:]*)/
objdump = `~cs254/bin/objdump -d #{path}`
# get only the <main> section
objdump = objdump[(objdump.index "<main>:\n")+8..-1]
# ignore everything after the next number <something> section
objdump = objdump[0..(objdump.index /[0-9a-f]+ +<[_a-z]+>:/)-1]
puts objdump


asmarray = objdump.scan(regex_obj)


regex_dwarf = /^0x([0-9a-f]+) *\[ *([0-9]+), *([0-9]+)/
dwarfdump = `~cs254/bin/dwarfdump #{path}`

dwarfarray = dwarfdump.scan(regex_dwarf)
puts "dwarf information:"
puts dwarfarray

dh = Hash.new()
dwarfarray.each { |x| dh[x[0].to_i(16)] = x[1] }





header = File.open("header.txt").read

footer = "</body></html>"

body = '<table class="dump">'

asmarray.each { |x|
    puts x[0] + ", " + x[1] + ", " + x[2] + ", " + x[3] + "\t\t(" + (dh[x[0].to_i(16)] != NIL ? dh[x[0].to_i(16)] : "Nil") + ")"
}

code_side = ""
asm_side = ""
asmarray.each { |x|
    if (dh[x[0].to_i(16)] != NIL)
        if (true)
            body += "<tr><td>" + code_side + "</td><td>" + asm_side + "</td></tr>"
        end
        code_side = ""
        asm_side = ""
    end
    # add in the div containing the line of assembly we are currently looking at
    asm_side += '<div class="asm-line"><div>' + x[0] + '</div><div>' + x[1] + '</div><div>' + x[2] + '</div><div>' + (x[3] == "" ? "&nbsp;" : x[3]) + '</div></div>'
}
body += "<tr><td>" + code_side + "</td><td>" + asm_side + "</td></tr>"

body += "
</table>"

File.write("index.html", header + body + footer)
