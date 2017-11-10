# get the name of the executable we are checking
if (ARGV.length == 0)
   abort("you must provide a path to an executable as an argument!") 
end
path = ARGV[0]

puts "executable: " + path + "\n\n"
# need a more precise regex that only captures main instructions, this is all just for figuring things out
regex_obj = /^[ \t]*([0-9a-f]{6}):[ \t]*((?: ?[0-9a-f]{2})+)[ \t]*([a-z]+) *([a-zA-Z0-9%,$@\(\) <>_\+\*\#\.:]*)/




# 1. asm address
# 2. line number
# 3. col number
# 4. ET if end of sequence, empty otherwise
# 5. the path of the uri if present, false otherwise
# will probably modify this standard later
regex_dwarf = /^0x([0-9a-f]+) *\[ *([0-9]+), *([0-9]+) *\](?:.* (ET))?(?:.* uri: "([\/a-zA-Z0-9_\-\.]+)")?/
dwarfdump = `~cs254/bin/dwarfdump #{path}`

dwarfarray = dwarfdump.scan(regex_dwarf)
#puts "dwarf information:"
#puts dwarfarray

# TODO: get dwarfdump sourcecode line bounds SEPARATELY
# may need to iterate over dwarfdump output in sequential order beforehand to determine which lines match up

# store information from source code in a hash table
sources = Hash.new()


# store directly corresponding lines from dwarfdump for each source file
dwarf_lines = Hash.new()

# for each source, we need:
# -last read line
# -highest line number read up to now
# use that information to add an "upperbound" value for line numbers (and a "read" value for single, already-read lines) for each dwarfdump entry


# use dwarfdump to find the highest and lowest addresses for instructions that have corresponding source code
$first_addr = Float::INFINITY
$last_addr = 0

dh = Hash.new()
uri = nil
prev_line = -1 # last source code line looked at, needed to merge some instructions with their sequential lines
prev_addr = 0 # same purpose as prev_line
# store the dwarfdump information in a more useful way, and add extra info to the entries
dwarfarray.each { |x|
    # parse address from assembly
    addr = x[0].to_i(16)
    
    if (addr < $first_addr)
        $first_addr = addr
    end
    if (addr > $last_addr)
        $last_addr = addr
    end
    # the same address can be referenced multiple times in dwarfdump
    if (x[4] != nil)
        uri = x[4]
        # add the source code file to the dwarf_lines hash table to determine which source code lines need to be read
        if (dwarf_lines[uri] == nil) # initialize for a given source file if needed
            dwarf_lines[uri] = [] # store list of source lines corresponding to that file
        end
    end
    # format:
    # 0. address
    # 1. line number end
    # 2. boolean (has this line already been read?  yes=true, no=false)
    # 3. uri
    # 4. is ET?  boolean
    entry_line = x[1].to_i(10)
    # TODO: combine ET sections with the previous one?  we probably want only one dwarfdump entry for a given assembly instruction, not several
    # in the case of ET, want to attach to prev group, then trigger stoppage of visiting lines
    if (true) #if (entry_line != prev_line || x[3] != nil)
        
        # insert the line into the source array if not yet there, preserving order
        # don't insert duplicates though
        found = false
        if (dwarf_lines[uri].length == 0)
            dwarf_lines[uri].push(entry_line)
        else
            i = dwarf_lines[uri].bsearch{|x| x == entry_line}
            if (i != nil)
                found = true
            else
                j = 0
                while (j < dwarf_lines[uri].length && dwarf_lines[uri][j] < entry_line)
                    j += 1
                end
                dwarf_lines[uri].insert(j, entry_line)
            end
        end

        
        
                
        # store the information about the dd line in the hash table
        # TODO: check if line is already present
        entry = [addr, entry_line, found, uri, (x[3] != nil)]
        
        if (dh[addr] == nil)
            dh[addr] = entry
        else # we already have souce code for this address
             # just update the ending line for that entry
            dh[addr][2] = entry_line
            
        end
        
    else # make it a continuation of the previously parsed dd instruction
        foo = 0 # do nothing
    end
    
    prev_line = entry_line
    prev_addr = addr
}
puts dh
puts dwarf_lines

printf("first address: 0x%x\n", $first_addr)
printf("last address:  0x%x\n", $last_addr)



# figure out bounds we need for objdump based on dwarfdump output
# start by capturing every line
objdump = `~cs254/bin/objdump -d #{path}`

objdump = objdump[objdump.index($first_addr.to_s(16) + ':') .. objdump.index($last_addr.to_s(16) + ':')]

# remove everything before <main>
#objdump = objdump[objdump.index(/[0-9a-f]+ <main>:/)..-1]
# remove everything past <__libc_csu_init>
# TODO: what if there is a function in the source called _libc_csu_init?
#objdump = objdump[0..objdump.index(/[0-9a-f]+ <__libc_csu_init>:/)-1]
asmarray = objdump.scan(regex_obj)

#puts objdump
#puts asmarray



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
        .gsub(' ', '&nbsp;') # convert spaces
        .gsub('<', '&lt;').gsub('>', '&gt;') # convert less than and greater than

    end
end

def add_jumps(s, instr)
    if (s == '')
        return '&nbsp;'
    else
        if (instr == 'jmp' || instr == 'je' || instr == 'callq')
            # check if the address being jumped to is in a valid range
            addr = s.scan(/^([0-9a-f]+)/)[0][0].to_i(16)
            if (addr >= $first_addr && addr <= $last_addr)
                return s.gsub(/^([0-9a-f]+)/, '<a onclick="document.getElementById(\'_\1\').style.backgroundColor = \'red\';" href="#_\1">\1</a>') # note that \1 in         double quotes needs to be escaped, like \\1
            end
        end
        return s
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

# if false, currently in a block of assembly with no direct correspondance to source code, so don't append lines to assembly side from now on until we find a match in dwarfdump
parsing_useful_asm = true
found_et = false

# iterate over objdump assembly to build the webpage
asmarray.each { |x|
    puts x.join(" ")
    # NOTE: do not want to iterate over every line
    # helper frames should be ignored
    # look up line in dwarfdump
    correspondance = dh[x[0].to_i(16)]
    if (correspondance != nil) # if we find a match, we probably create a new table row
        puts correspondance.join(" ")
        parsing_useful_asm = true # start recording asm lines if we weren't currently
        # check if this entry is a special one marking the end of a text sequence
        if (correspondance[4])
            found_et = true # used to make sure we attach this line to the current block, but trigger ignore asm starting on the next line
        else # otherwise cut off the block
            # cut off the old table row
            if (first_iteration)
                first_iteration = false
            else
                html_table += '<tr><td>' + html_source + '</td><td>' + html_asm + '</td></tr>'
                html_asm = '';
                html_source = '';
                first_iteration = false
            end
            if (correspondance[3] != cur_file)
                cur_file = correspondance[3]
                sources[cur_file] = get_file_array(cur_file)
            end
            # get all the corresponding source code
            # we know the ending line, but need to calculate the starting line
            i = 0
            while (i < dwarf_lines[uri].length && dwarf_lines[uri][i] < correspondance[1])
                i += 1
            end
            if (i == dwarf_lines[uri].length)
                puts "error: could not find line in dwarfdump"
                puts correspondance.join(" ")
                puts dwarf_lines[cur_file].join(" ")
                puts ""
            else
                low = (i == 0 ? 1 : dwarf_lines[cur_file][i-1]+1)
                high = dwarf_lines[cur_file][i]
                if (correspondance[2])
                    low = high
                end
                printf("i: %d\n", i)
                printf("low: %d, high: %d\n", low, high)
                sources[cur_file][low-1..high-1].each_with_index do |line, index|
                    html_source += '<div class="src-line' + (correspondance[2] ? ' grey' : '') + '"><div>' + (index+low).to_s + '.</div><div>' + htmlify_string(line) + '</div></div>'
                end
            end
        end
              
        
              
        # check if we reached the end of a block and should stop including assembly instructions
        
        
        #if (correspondance[2] != cur_file)
            
            
        # check if the current file changed (load that file's code if we haven't already)
        # check if we need to create a new row
            # if we do, append the finished row and reset the html_* vars
            # if we do, get all the source code for that row immediately
        #end
    end
    # add the current line of assembly to the row
    if (parsing_useful_asm)
        html_asm += '<div id="_' + x[0] + '"class="asm-line"><div>' + x[0] + '</div><div>' + x[1] + '</div><div>' + x[2] + '</div><div>' + add_jumps(x[3], x[2]) + '</div></div>'
        if (found_et)
            parsing_useful_asm = false
            found_et = false
        end
    end
}

# close off current row
html_table += '<tr><td>' + html_source + '</td><td>' + html_asm + '</td></tr>'

# write to file
header = File.open("header.txt").read
footer = '</body></html>'

File.write("index.html", header + '<table class="dump">' + html_table + '</table>' + footer)














