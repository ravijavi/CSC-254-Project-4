Jeremy Spiro(jspiro2@u.rochester.edu), Ravi Jain (rjain8@u.rochester.edu), CSC 254, MW 10:25-11:40, Prof. Michael Scott

For Assignment A4, I worked with Jeremy Spiro. In this project, we implemented a cross indexer in Ruby that parsed a given set of assembly instructions from a C file and outputted an HTML file; the resulting HTML file contained a side-by-side comparison between the original source code and the corresponding assembly. Ultimately, we had to implement an xref program that could:

1) run objdump -d myprogram and examine the output to obtain the assembly language version of the program
2) run dwarfdump and examine the output to learn the names of the source files and the code rangers in the program corresponding to each line in those files
3) Convert the source code to HTML, with side-by-side assembly and source, and with embedded branch-target links
4) place the HTML into a subdirectory named HTML, with an extra file index.html that contains a link to the main HTML files, a location-specific link to the beginning of the code for main, and information about when and where the xref tool was run

---------------------------------------------------------------------------------------------------

IMPLEMENTATION:
Our first step was to successfully feed files into dwarfdump and output a corresponding list of instructions and registers and memories used in the execution of the program. We created the following regex for dwarfdump:

/^0x([0-9a-f]+) *\[ *([0-9]+), *([0-9]+) *\](?:.* (ET))?(?:.* uri: "([\/a-zA-Z0-9_\-\.]+)")?/

This line successfully provided us with all the important information we would need to glean from dwarfdump to create our HTML output.

Our next step was to write a parser in a scripting language (we chose Ruby due to its elegant handling of regular expressions) and parse the information that could be outputted as a an HTML file. We stored necessary information from the source code in a hash table; for each line of source code, we were interested in the most recently read line and the highest recorded source line number up to that point. From there, we utilized that information to add attributes for upperbound values that preceded the current source line and a marker for which lines had already been read. This would allow us to ensure that no redundant print statements were made in our final output. Our hash table would also include information about the address, line number start and end (if needed and not redundant), a boolean to delimit whether or not the line had already been read, and a URI directory. 

For the construction of the webpage, we iterate over objump assembly, but ensure that we do not iterate over the entire body (helper frames are ommitted). We then do a lookup of the information in dwarfdump and check the correspondance between the source code and the assembly through an array that contains the hash table information for dwarfdump. When a match is found, a new table row is created. We also record the starting and ending lines to process the ends of the methods as well as to signify when a new file is being parsed. It is done in a succinct order.

-----------------------------------------------------------------------------------------------------------------------

HOW TO RUN:

--------------------------------------------------------------------------------------------------------------------------
EXAMPLE OUTPUT:

For "main":

For "hello":

For "loop":


