# get the name of the executable we are checking
if (ARGV.length == 0)
   abort("you must provide a path to an executable as an argument!") 
end
path = ARGV[0]

puts "executable: " + path + "\n\n"
# need a more precise regex that only captures main instructions, this is all just for figuring things out
regex_obj = /^[ \t]*([0-9a-f]{6}):[ \t]*((?: ?[0-9a-f]{2})+)[ \t]*([a-z]+) *([a-zA-Z0-9%,$@\(\) <>_\+\*\#\.:]*)/

# will want everything from <main> up to <libc_csu_init>
# for now, capture every line
objdump = `~cs254/bin/objdump -d #{path}`

# remove everything before <main>
objdump = objdump[objdump.index(/[0-9a-f]+ <main>:/)..-1]
# remove everything past <__libc_csu_init>
# TODO: what if there is a function in the source called _libc_csu_init?
objdump = objdump[0..objdump.index(/[0-9a-f]+ <__libc_csu_init>:/)-1]
asmarray = objdump.scan(regex_obj)

puts objdump


# 1. asm address
# 2. line number
# 3. col number
# 4. ET if end of sequence, empty otherwise
# 5. the path of the uri if present, false otherwise
# will probably modify this standard later
regex_dwarf = /^0x([0-9a-f]+) *\[ *([0-9]+), *([0-9]+) *\](?:.*(ET))?(?:.*uri: "([\/a-zA-Z0-9_\-\.]+)")?/
dwarfdump = `~cs254/bin/dwarfdump #{path}`

dwarfarray = dwarfdump.scan(regex_dwarf)
#puts "dwarf information:"
#puts dwarfarray

# TODO: get dwarfdump sourcecode line bounds SEPARATELY
# may need to iterate over dwarfdump output in sequential order beforehand to determine which lines match up

# store information from source code in a hash table
sources = Hash.new()
# for each source, we need:
# -last read line
# -highest line number read up to now
# use that information to add an "upperbound" value for line numbers (and a "read" value for single, already-read lines) for each dwarfdump entry



dh = Hash.new()
uri = nil
# store the dwarfdump information in a more useful way, and add extra info to the entries
dwarfarray.each { |x|
    # parse address from assembly
    addr = x[0].to_i(16)
    # the same address can be referenced multiple times in dwarfdump
                
    if (x[4] != nil)
        uri = x[4]
        # add the source code file to the sources hash table to determine which source code lines need to be read
        if (sources[uri] == nil)
            sources[uri] = 0 # the highest line number read so far
        end
    end
    
    # store hash table entries in buckets (arrays)
    
    # format:
    # 0. address
    # 1. line number start
    # 2. line number end (inclusive?)
    # 3. boolean (has this line already been read?  yes=true, no=false)
    # 4. uri
    entry_line = x[1].to_i(10)
    # TODO: combine ET sections with the previous one?  we probably want only one dwarfdump entry for a given assembly instruction, not several
    entry = 0
    entry = [addr, (entry_line > sources[uri] ? sources[uri]+1 : entry_line), entry_line, (entry_line < sources[uri]), uri]
    if (entry_line > sources[uri])
        sources[uri] = entry_line
    end
    if (dh[addr] == nil)
        dh[addr] = [entry]
    elsif # we already have souce code for this address
        dh[addr].push(entry)
    end
}
puts dh


# TODO: open up source files, mark when lines are visited

# global variables used over several iterations
cur_file = '' # the source file of the last asm line successfully matched in dwarfdump
cur_line = '' # the sc line of the last asm line successfully matched in dwarfdump

html_table = '' # the contents of the <table> tag
html_asm = '' # formatted HTML of the current cell for the assembly side
html_source = '' # formatted c code of the current cell for the source code side


# iterate over objdump assembly to build the webpage
asmarray.each { |x|
    # look up line in dwarfdump
    correspondance = dh[x[0].to_i(16)]
    if (correspondance != nil) # if we find a match, we probably create a new table row
        puts x[0]
        if (correspondance[2] != cur_file)
        # check if the current file changed (load that file's code if we haven't already)
        # check if we need to create a new row
            # if we do, append the finished row and reset the html_* vars
            # if we do, get all the source code for that row immediately
            x = 0
        end
    else # append the assembly to the html_asm side
        puts 'foo'
    end
}














def get_file_array(path)
    array = []
    File.open(path) do |f|
        f.each_line do |line|
            array.push(line)
        end
    end
    return array
end


header = File.open("header.txt").read

footer = "</body></html>"

body = '<table class="dump">'

#asmarray.each { |x|
#    puts x[0] + ", " + x[1] + ", " + x[2] + ", " + x[3] + "\t\t(" + (dh[x[0].to_i(16)] != nil ? dh[x[0].to_i(16)] : "Nil") + ")"
#}




































=begin
# iterate over all the lines we got from the dwarfdump output
# that way, we build the information for one file at a time
enum = asmarray.each
cur_enum = enum.next

content = ""
side_source = ""
side_asm = ""


source = []
cur_addr = 0
cur_line = 0
prev_addr = 0
prev_line = 0
prev_line2 = 0
max_line = 0
max_line2 = 0
dwarfarray.each { |x|
    cur_addr = x[0].to_i(16)
    cur_line = x[1].to_i(10)
    if (x[4] != nil)
        puts "uri: " + x[4]
        source = get_file_array(x[4])
        side_source = ""
        side_asm = ""
    end
    if (prev_line > 0)
        #printf("current: 0x%x (%d) (%d)\n", prev_addr, prev_line, max_line)
    end
                
                
    if (prev_line != prev_line2)
        content += '<tr><td>' + side_source + '</td><td>' + side_asm + '</td>'
        side_source = ""
        side_asm = ""
    end
    # print source
    # rules: if prev_line < max_line, print just prev_line
    #        if prev_line == prev_line2, don't print
    #        else print from old max to prev_line-1
    #printf("addr: 0x%x\t", prev_addr)
    
    if prev_line == prev_line2
        
    elsif prev_line < max_line
        line = (source[prev_line-1] == "" ? '&nbsp;' : source[prev_line-1].strip)
        line.sub! '<', '&lt;'
        line.sub! '>', '&gt;'
        side_source += '<div class="src-line"><div>' + line + '</div></div>'
        puts source[prev_line-1]
    else
        (max_line2..prev_line-1).each { |i|
            line = (source[i] == "" || source[i] == nil ? '&nbsp;' : source[i].strip)
            line.sub! '<', '&lt;'
            line.sub! '>', '&gt;'
            side_source += '<div class="src-line"><div>' + line + '</div></div>'
            puts source[i]
        }
    end
                
    # add all assembly in the address range to the current chunk
    while cur_addr > cur_enum[0].to_i(16) do
        puts cur_enum[0] + ", " + cur_enum[1] + ", " + cur_enum[2] + ", " + cur_enum[3]
        side_asm += '<div class="asm-line"><div>' + cur_enum[0] + '</div><div>' + cur_enum[1] + '</div><div>' + cur_enum[2] + '</div><div>' + (cur_enum[3] == "" ? "&nbsp;" : cur_enum[3]) + '</div></div>'
        cur_enum = enum.next
    end
    prev_line2 = prev_line
    prev_addr = cur_addr
    prev_line = cur_line
    max_line = (prev_line > max_line ? prev_line : max_line)
    max_line2 = (prev_line2 > max_line2 ? prev_line2 : max_line2)
    # if cur_line is different from prev_line, we found the end of a "chunk": wrap it up as a table row, paste in the matching source code lines, and start the next chunk
}
# note that last line in dwarf contains the final address, so we iterate over the enum differently
#printf("current: 0x%x (%d)\n", prev_addr, prev_line)
puts cur_enum[0] + ", " + cur_enum[1] + ", " + cur_enum[2] + ", " + cur_enum[3]
while cur_addr > cur_enum[0].to_i(16) do
    cur_enum = enum.next
    side_asm += '<div class="asm-line"><div>' + cur_enum[0] + '</div><div>' + cur_enum[1] + '</div><div>' + cur_enum[2] + '</div><div>' + (cur_enum[3] == "" ? "&nbsp;" : cur_enum[3]) + '</div></div>'
    puts cur_enum[0] + ", " + cur_enum[1] + ", " + cur_enum[2] + ", " + cur_enum[3]
end
side_asm += '<div class="asm-line"><div>' + cur_enum[0] + '</div><div>' + cur_enum[1] + '</div><div>' + cur_enum[2] + '</div><div>' + (cur_enum[3] == "" ? "&nbsp;" : cur_enum[3]) + '</div></div>'


content += '<tr><td>' + side_source + '</td><td>' + side_asm + '</td>'
side_source = ""
side_asm = ""


File.write("index.html", header + '<table class="dump">' + content + '</table>' + footer)

code_side = ""
asm_side = ""
asmarray.each { |x|
    if (dh[x[0].to_i(16)] != nil)
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

#File.write("index.html", header + body + footer)
=end
