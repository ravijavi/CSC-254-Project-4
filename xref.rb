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
prev_line = -1 # last source code line looked at, needed to merge some instructions with their sequential lines
prev_addr = 0 # same purpose as prev_line
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
    if (entry_line != prev_line)
        entry = 0
        entry = [addr, (entry_line > sources[uri] ? sources[uri]+1 : entry_line), entry_line, (entry_line < sources[uri]), uri]
        if (entry_line > sources[uri])
            sources[uri] = entry_line
        end
        if (dh[addr] == nil)
            dh[addr] = entry
        elsif # we already have souce code for this address
            dh[addr][2] = entry_line
        end
    else # make it a continuation of the previously parsed dd instruction
        x = 0 # do nothing
                
    end
    
    prev_line = entry_line
    prev_addr = addr
}
puts dh




def get_file_array(path)
    array = []
    File.open(path) do |f|
        f.each_line do |line|
            array.push(line)
        end
    end
    return array
end

def htmlify_string(s)
    s = s.rstrip
    if (s == '')
        return '&nbsp;'
    else
        return s.gsub('\n', '') #remove trailing newlines
        .gsub('<', '&lt;')

    end
end



# TODO: open up source files, mark when lines are visited

# global variables used over several iterations
cur_file = '' # the source file of the last asm line successfully matched in dwarfdump
cur_line = '' # the sc line of the last asm line successfully matched in dwarfdump

html_table = '' # the contents of the <table> tag
html_asm = '' # formatted HTML of the current cell for the assembly side
html_source = '' # formatted c code of the current cell for the source code side

first_iteration = true

# iterate over objdump assembly to build the webpage
asmarray.each { |x|
    # NOTE: do not want to iterate over every line
    # helper frames should be ignored
    # look up line in dwarfdump
    correspondance = dh[x[0].to_i(16)]
    if (correspondance != nil) # if we find a match, we probably create a new table row
        # cut off the old table row
        if (first_iteration)
            first_iteration = false
        else
            html_table += '<tr><td>' + html_source + '</td><td>' + html_asm + '</td></tr>'
            html_asm = '';
            html_source = '';
            first_iteration = false
        end
        if (correspondance[4] != cur_file)
            cur_file = correspondance[4]
            sources[cur_file] = get_file_array(cur_file)
        end
        puts correspondance
        # get all the corresponding source code
        sources[correspondance[4]][correspondance[1]-1..correspondance[2]-1].each_with_index do |line, index|
            html_source += '<div class="src-line"><div>' + (index+correspondance[1]).to_s + '.</div><div>' + htmlify_string(line) + '</div></div>'
        end
        
        #if (correspondance[2] != cur_file)
            
            
        # check if the current file changed (load that file's code if we haven't already)
        # check if we need to create a new row
            # if we do, append the finished row and reset the html_* vars
            # if we do, get all the source code for that row immediately
        #end
    end
    # add the current line of assembly to the row
    html_asm += '<div class="asm-line"><div>' + x[0] + '</div><div>' + x[1] + '</div><div>' + x[2] + '</div><div>' + (x[3] == "" ? "&nbsp;" : x[3]) + '</div></div>'
}

# close off current row
html_table += '<tr><td>' + html_source + '</td><td>' + html_asm + '</td></tr>'

# write to file
header = File.open("header.txt").read
footer = '</body></html>'

File.write("index.html", header + '<table class="dump">' + html_table + '</table>' + footer)














