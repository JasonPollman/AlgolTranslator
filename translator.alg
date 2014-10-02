# ---------------------------------------------------
  The Translator — translator.alg
  Algol68
  Compiled using Algol Genie (a68g)

  ITCS 4102 - Term Project, Spring 2014
  Jason Pollman, Walter Alfaro, Robert Iannucci
  --------------------------------------------------- #


# ------------------------------------------------- STRUCTS ------------------------------------------------- #

# A "definition" struct to define a translation....
  Properties:
  @ STRING original string        - The actual line read in from the glossary in a string format.
  @ STRING foreign word           - The non-english version of the word.
  @ [] STRING english translation - Up to 5 versions of the word in english.
  @ INT line number               - The line number read in from the glossary file. 
#
MODE DEFINITION = STRUCT (STRING original string, STRING foreign word, [5] STRING english translation, INT line number);

# A dictionary of 1024 definitions... #
# 1024, Overkill? Likely. #
MODE DICTIONARY = STRUCT ([1024] DEFINITION phrase);

# Operator that determines if a DEFINITION STRUCT is empty #
OP DEFINITIONISEMPTY = (DEFINITION this) BOOL:
  (original string     OF this)    = "" &
  (foreign word        OF this)    = "" &
  (english translation OF this)[1] = "" &
  (english translation OF this)[2] = "" &
  (english translation OF this)[3] = "" &
  (english translation OF this)[4] = "" &
  (english translation OF this)[5] = "";

# Operator that determines if a DEFINITION STRUCT is NOT empty #
OP DEFINITIONISNOTEMPTY = (DEFINITION this) BOOL:
  NOT(
  (original string     OF this)    = "" &
  (foreign word        OF this)    = "" &
  (english translation OF this)[1] = "" &
  (english translation OF this)[2] = "" &
  (english translation OF this)[3] = "" &
  (english translation OF this)[4] = "" &
  (english translation OF this)[5] = "");


# ------------------------------------------------ CONSTANTS ------------------------------------------------ #

STRING dictionary default filename  := "4102proj/dictionaries/default.dictionary";   # Default dictionary file #
STRING translate default filename   := "4102proj/translate/example.t";  # Default translation file #

# Guess I have to create my own tab character here! 9 = ASCII for tab #
CHAR tab = REPR 9;


# ------------------------------------------------- GLOBALS ------------------------------------------------- #

# The user's preferred translation options #
[4] INT preferred;

# The language were translating from #
STRING lang from;

# The language were translating to #
STRING lang to;


# ---------------------------------------------- BEGIN PROGRAM ---------------------------------------------- #

# Main function. #
# Controls program flow, setup like a C style program, e.g. main calls all other functions #
PROC main = VOID:
  BEGIN
    # Print the program welcome message. #
    print headers;

    # Sentinel value for mode so it will run the WHILE loop at least once. # 
    INT mode := 99;

    # WHILE the user does not select "quit" do: #
    WHILE mode /= 2 DO
      printf(($l, l, "Main Menu: ", l, "(1) Translate A File", l, "(2) Quit", l, l, "Select: "$));
      read (mode);

      IF mode /= 1 & mode /= 2 THEN
        printf(($l, "Please enter a valid option: Which translation mode would you like to use?", l, "(1) Translate A File", l, "(2) Quit", l, l, "Select: "$));
        read (mode)
      FI;

      # If the user selects 1, goto file mode. #
      IF mode = 1 THEN file mode FI

    OD # End WHILE loop #

  END; # End of main procedure #


# Allows the user to translate an entire file. #
PROC file mode = VOID:
  BEGIN

    # Get the preferred translation options #
    preferred := get preferred options;

    printf(($l, "Enter the filename of the dictionary to translation with: "$));
    # Must specify a new line for stdin to read a string or it will just skip over the read! #
    new line (stand in);

    # Read in the filename for the dictionary file #
    STRING filename;
    read (filename);

    # Read in the dictionary file, then process it. #
    FILE f := get file (filename, "dictionary");
    DICTIONARY d := process dictionary(f);
    close(f);

    printf(($"Enter the filename of the file to be translated: "$));
    # Must specify a new line for stdin to read a string or it will just skip over the read! #
    new line (stand in);

    # Read in the filename for the translation file #
    read (filename);

    # Read in the translation file, then translate it. #
    f := get file (filename, "translation");
    translate(f, d);
    close(f)

  END; # End of file mode procedure #


# This procedure translates the specified file from 'lang from' to 'lang to' #
# @ FILE f - The file to translate #
# @ DICTIONARY d - The "glossary" or DICTIONARY STRUCT for translation lookup. # 
PROC translate = (REF FILE f, DICTIONARY d) VOID:
  BEGIN

    STRING line;
    get (f, line);

    [2048] STRING line words;
    [2048][50] CHAR words;

    # Initialize with "blanks" (e.g. " ") #
    FOR i FROM 1 TO UPB words DO
      FOR n FROM 1 TO UPB words[i] DO
        words[i][n] := " "
      OD
    OD;

    INT z := 1;

    # Until we reach the end of the translation file... #
    WHILE(NOT end of file(f)) DO
      
      get(f, (line, new line));

      
      INT k := 1;

      # If the character of the line is blank, then we need to increment k, #
      # since we have a new word. #
      FOR i FROM 1 TO UPB line DO
        IF(line[i] /= blank) THEN
          words[z][k] := line[i];
          k := k + 1
        ELSE

          z := z + 1;
          k := 1
        FI
      OD;

      # Set the STRING line words := the [] CHAR words #
      line words := words
    OD;

    # The words that have been trimmed, omitting extra CHAR space. #
    [z] STRING real words;

    # A STRING to print the words in "sentence form". #
    [z] STRING sentence form;

    # Actually trim the words, using the trim procedure — defined below #
    FOR i FROM 1 TO UPB real words DO
      real words[i] := trim(line words[i])
    OD;

    INT j := 1;

    # Print output headers #
    printf(($l, "     ", g, g, g$, lang from, tab, lang to));
    printf(($l, "     --------- ---------"$));

    # Print translation output and lookup the words in the dictionary #
    FOR i FROM 1 TO UPB real words DO

      # For tab alignment... at least on console. #
      IF UPB real words[i] < 3 THEN
        printf(($l 3d, ": ", g, g, g$, i, real words[i], tab, tab))
      ELSE
        printf(($l 3d, ": ", g, g$, i, real words[i], tab))
      FI;

      # @ show it: If the word is in the dictionary, then print the translation #
      BOOL show it := FALSE;

      # Index of the english translation item in the dictionary. #
      INT index := 0;

      # Determine whether or not to print the word or a '-?-' #
      FOR n FROM 1 TO UPB (phrase OF d) DO
        IF(real words[i] = (foreign word OF phrase OF d)[n]) THEN show it := TRUE; index := n FI
      OD;

      IF(show it = TRUE) THEN

        INT use option := 1;

        # Print the preferred option, if it exists, else the secondary, then terinary #
        IF(UPB (english translation OF phrase OF d)[index][preferred[4]] /= 0) THEN use option := preferred[4] FI;
        IF(UPB (english translation OF phrase OF d)[index][preferred[3]] /= 0) THEN use option := preferred[3] FI;
        IF(UPB (english translation OF phrase OF d)[index][preferred[2]] /= 0) THEN use option := preferred[2] FI;
        IF(UPB (english translation OF phrase OF d)[index][preferred[1]] /= 0) THEN use option := preferred[1] FI;

        printf(($g$, (english translation OF phrase OF d)[index][use option]));
        sentence form[j] := ((english translation OF phrase OF d)[index][use option])
      ELSE
        printf(($g$, "-?-"));
        sentence form[j] := "-?-"  
      FI;

      j := j + 1
    OD;

    # Print the output in sentence form for easy reading #
    print((new line, new line));
    printf(($l, g, ":", l$, lang from));
    printf(($gx$, real words));

    print((new line));
    printf(($l, g, ":", l$, lang to));
    printf(($gx$, sentence form));

    # Print the output to file #
    STRING fn;
    printf(($l, l, l, "Enter a file location to save the output: "$));
    new line(stand in);
    read(fn);

    # @ See PROC write output, below #
    write output(real words, sentence form, fn);

    # Tell the user we saved the file. #
    printf(($l, "Output saved to file: ", g$, fn));

    STRING temp;
    new line(stand in);
    printf(($l, l, l, "PRESS ENTER TO CONTINUE... "$));
    read(temp)

    # Return to main loop #

  END; # End of translate procedure #


# Prints the translation output to file. #
# @ [] STRING foreign - The forign input array from the translation file. #
# @ [] STRING english - The english translation from the translation file. #
# @ STRING filename - The file location to save the file, RELATIVE to this program. #
PROC write output = ([] STRING foreign, english, STRING filename) VOID:
  BEGIN
    FILE f;

    # If we can't write to the file, tell the user #
    IF establish (f, filename, stand out channel) /= 0 THEN
      put (stand error, ("There was an error generating the file."))

    # Else write the translation to file #
    ELSE
      FOR i FROM 1 TO UPB foreign DO
        IF UPB foreign[i] <= 3 THEN
          put (f, (foreign[i], tab, tab, english[i], new line))
        ELSE
          put (f, (foreign[i], tab, english[i], new line))
        FI
      OD;

      put(f, (newline, lang from, ":", new line));

      FOR i FROM 1 TO UPB foreign DO
        put(f, (foreign[i], " "))
      OD;

      put(f, (new line, new line, lang to, ":", new line));

      FOR i FROM 1 TO UPB foreign DO
        put(f, (english[i], " "))
      OD;

      close (f)
    FI

  END; # End of write output procedure #


# Reads in the glossary file... #
# @ STRING filename - The location of the file — RELATIVE to this program! #
# @ RETURN - Returns a file for processing. #
PROC get file = (STRING filename, STRING type) FILE:
  BEGIN

    STRING fn := filename;
    # A file struct #
    FILE file;

    IF (fn = "default" & type = "dictionary") THEN fn := dictionary default filename FI;
    IF (fn = "default" & type = "translation") THEN fn := translate default filename FI;

    IF file is regular (fn) THEN
      VOID (open(file, fn, stand back channel));

      # Return the dictionary file #
      file

    ELSE
        # The file wasn't found, try again: #
        printf(($l, "Error: There was an error opening the file at the specified location: '", g, "'."$, fn));
        printf(($l, "Enter a new filename, or 'default' to use the default ", g, " file: "$, type));

        # Get new filename #
        new line (stand in);

        STRING new filename;
        read (new filename);

        # If the user inputs default, use the default filename constants #
        IF (new filename = "default" & type = "dictionary") THEN
          file := get file(dictionary default filename, type)
        ELIF (new filename = "default" & type = "translation") THEN
          file := get file(translate default filename, type)
        ELSE 
          # User entered a new filename, recurse #
          file := get file(new filename, type)
        FI

    FI # End if statement #

  END; # End of get dictionary file procedure #


# Processes the dictionary file for translation, #
# E.G. - Breaks down each line into its english / other language counterparts #
# @ REF FILE file - The file handle served up by the get dictionary file procedure. #
# @ RETURN - Returns a DICTIONARY struct for translation. #
PROC process dictionary = (REF FILE file) DICTIONARY:
  BEGIN

    # Define our dictionary struct #
    DICTIONARY d;

    # Get the 'lang from' & 'lang to' definitions from the dictionary file #
    STRING langs;
    get (file, langs);
    new line (file);

    [50] CHAR lang from char;
    [50] CHAR lang to char;

    FOR i FROM 1 TO UPB lang from char DO
      lang from char [i] := blank;
      lang to char [i] := blank
    OD;

    BOOL found slash := FALSE;
    INT n := 1;
    INT k := 1;

    FOR i FROM 1 TO UPB langs DO
      IF found slash = FALSE THEN
        IF langs[i] = "/" THEN
          found slash := TRUE
        ELSE
          lang from char[k] := langs[i];
          k := k + 1
        FI
      ELSE
        lang to char[n] := langs[i];
        n := n + 1
      FI
    OD;

    lang from := trim(lang from char);
    lang to := trim(lang to char);

    INT i := 1;
    WHILE (i <= 1024) DO

        IF end of file(file) THEN
          # Assign line number to d.lineNumber #
          (line number OF phrase OF d)[i] := i
        ELSE
          STRING read;
          get(file, (read, new line));
          # Assign line contents to d.originalString #
          (original string OF phrase OF d)[i] := read;

          # Break down the original line into it's counterparts #
          (foreign word OF phrase OF d)[i] := get foreign ((original string OF phrase OF d)[i]);
          (english translation OF phrase OF d)[i] := get english ((original string OF phrase OF d)[i]);

          # Assign line number to d.lineNumber #
          (line number OF phrase OF d)[i] := i
        FI;

        i := i + 1
        
    OD;

    close(file);

    # Return the dictionary #
    d

  END; # End of process dictionary procedure #


# Grabs the foreign word from the original file line #
PROC get foreign = (STRING line) STRING:
  BEGIN

    STRING real foreign word; 

    [256] CHAR temp foreign word;
    INT i := 1;

    # Set the CHAR temp to the line[i] value, until a comma is reached. #
    DO
      temp foreign word[i] := line[i];
      i := i + 1
    UNTIL 
      line[i] = ","
    OD;

    # Set foreign word to temp, but only for the valid bounds (1:i-1) #
    [i-1] CHAR foreign word;

    FOR i FROM 1 TO UPB foreign word DO
      foreign word[i] := temp foreign word[i]
    OD;

    # Return the STRING real foreign word #
    real foreign word := foreign word

  END;


# Grabs the english word(s) from the original file line #
PROC get english = (STRING line) [] STRING:
  BEGIN

    # Initialize our english translation array #
    [5] STRING english translation;

    [150] CHAR temp string;

    # Weed out the foreign word, by seeking the line until we reach the first comma #
    # If true, we know we're into the english equivalents now. #
    BOOL first comma found := FALSE;

    # Assign the word to an temp CHAR, then we can trim it later #
    INT n := 1;
    FOR i FROM 1 TO UPB line DO
      IF first comma found = TRUE THEN
        
        temp string[n] := line[i];
        n := n + 1

      ELSE
        IF line[i] = "," THEN first comma found := TRUE FI
      FI
    OD;

    [n - 1] CHAR english string;
    FOR i FROM 1 TO UPB english string DO
      english string[i] := temp string[i]
    OD;

    # We can support up to 5 english words for each foreign word #
    # Each up to 256 CHARS in length #
    [5][256] CHAR temp translations;

    # Initialize temp translation CHAR ARRAY with "@'s" #
    FOR i FROM 1 TO UPB temp translations DO
      FOR j FROM 1 TO UPB temp translations[i] DO
        temp translations[i][j] := "@"
      OD
    OD;

    n := 1;
    INT z := 1;

    FOR i FROM 1 TO UPB english string DO
      IF english string[i] = "," THEN
        # We found the next comma, increment n to move to the next word and reset z to start #
        # The next char at index 1 #
        n := n + 1;
        z := 1
      ELSE
        temp translations[n][z] := english string[i];
        z := z + 1
      FI
    OD;

    # Holds the proper, trimmed lenght english equivalent words #
    [5] STRING trimmed translations;
    INT count;

    # Get the actual non-sentinel (e.g. "@") CHARS to put the CHARS in a proper length STRING #
    FOR i FROM 1 TO UPB temp translations DO

      count := 0;
      FOR j FROM 1 TO UPB temp translations[i] DO
        IF temp translations[i][j] /= "@" THEN
          count := count + 1
        FI
      OD;

      [count] CHAR temp;
      FOR j FROM 1 TO count DO
        temp[j] := temp translations[i][j]
      OD;

      # Make sure we trim and white space @ see 'trim' procedure below #
      trimmed translations[i] := trim (temp)
    OD;

    # Set the STRING ARRAY equal to the [][] CHAR ARRAY #
    english translation := trimmed translations
  END;


# Prints a dictionary — for debugging. #
PROC print dictionary = (DICTIONARY d) VOID:
  BEGIN
    FOR i FROM 1 TO UPB (phrase OF d) DO
      IF (DEFINITIONISNOTEMPTY (phrase OF d)[i]) THEN
        printf(($l, g(3), ": ", g, " | ", g, " | ", g, " | ", g, " | ", g, " | ", g, " | ", g, l$,
        (line number OF phrase OF d)[i],
        (original string OF phrase OF d)[i],
        (foreign word OF phrase OF d)[i],
        (english translation OF phrase OF d)[i]))
      FI
    OD
  END;


# Trims whitespace from the beginning and end of strings #
PROC trim = (STRING this) STRING:
  BEGIN

    INT lower bound := 1;
    INT upper bound := UPB this;

    # Find upper bound #
    FOR n FROM 1 TO UPB this DO
      IF this[n] = " " THEN
        lower bound := lower bound + 1
      ELSE
        GOTO stoplower
      FI
    OD;

    stoplower:

    # Find upper bound #
    FOR n FROM UPB this DOWNTO 1 DO
      IF this[n] = " " THEN
        upper bound := upper bound - 1
      ELSE
        GOTO stopupper
      FI
    OD;

    stopupper:

    # Return the trimmed string #
    this[lower bound : upper bound]
  END;

# Prints the program header and welcome message. #
PROC print headers = VOID:
  printf(($l, "The Translator", l, "------------------------------"$));


# Sets the preferred options array, to specify the first, second, and third choice for translation. #
PROC get preferred options = [] INT:
  BEGIN

    # Get the user's preferred translation options... #
    [4] INT preferred := (0, 0, 0, 0);

    # Read option number one... #
    printf(($l, "Enter your preferred translation option (1, 2, 3, or 4): "$));
    read (preferred[1]);

    # Verify Input for option one. #
    WHILE(preferred[1] /= 1 & preferred[1] /= 2 & preferred[1] /= 3 & preferred[1] /= 4) DO
      printf(($l, "Please enter either a 1, 2, 3, or 4: "$));
      read (preferred[1])
    OD;

    # Read option number two... #
    printf(($"Enter your secondary translation option (1, 2, 3, or 4): "$));
    read (preferred[2]);

    # Verify Input for option two. #
    WHILE(preferred[2] /= 1 & preferred[2] /= 2 & preferred[2] /= 3 & preferred[2] /= 4) DO
      printf(($l, "Please enter either a 1, 2, 3, or 4: "$));
      read (preferred[2])
    OD;

    # If options two is chosen the same as option one, ask until the user picks something else. #
    WHILE preferred[2] = preferred[1] DO
      printf(($l, "You've already entered ", g(0), " as your preferred option. Choose another option: "$, preferred[1]));
      read (preferred[2])
    OD;

    # Read option number three... #
    printf(($"Enter your tertiary translation option (1, 2, 3, or 4): "$));
    read (preferred[3]);
    new line;

    # Verify Input for option three. #
    WHILE(preferred[3] /= 1 & preferred[3] /= 2 & preferred[3] /= 3 & preferred[3] /= 4) DO
      printf(($l, "Please enter either a 1, 2, 3, or 4: "$));
      read (preferred[3])
    OD;

    # If options three is chosen the same as option one or two, ask until the user picks something else. #
    WHILE(preferred[3] = preferred[1] OR preferred[3] = preferred[2]) DO
      WHILE(preferred[3] /= 1 & preferred[3] /= 2 & preferred[3] /= 3 & preferred[3] /= 4) DO
        printf(($l, "Please enter either a 1, 2, 3, or 4: "$));
        read (preferred[3])
      OD;

      IF(preferred[3] = preferred[1]) THEN
        printf(($l, "You've already entered ", g(0), " as an option. Choose another option: "$, preferred[1]))
      ELSE
        printf(($l, "You've already entered ", g(0), " as an option. Choose another option: "$, preferred[2]))
      FI;
      read (preferred[3])
    OD;

    # Deduce the fourth option from the results of the first two. #
    IF(preferred[1] + preferred[2] + preferred[3] = 9) THEN
      preferred[4] := 1
    ELIF(preferred[1] + preferred[2] + preferred[3] = 8) THEN
      preferred[4] := 2
    ELIF(preferred[1] + preferred[2] + preferred[3] = 7) THEN
      preferred[4] := 3
    ELSE
      preferred[4] := 4
    FI;


    # Return preferred #
    preferred

  END; # End of get preferred options procedure. #



# Call the main procedure...  and begin the program #
main