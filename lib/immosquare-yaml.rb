require          "English"
require          "immosquare-extensions"
require_relative "immosquare-yaml/configuration"
require_relative "immosquare-yaml/shared_methods"
require_relative "immosquare-yaml/translate"
require_relative "immosquare-yaml/railtie" if defined?(Rails)

##===========================================================================##
## Importing the 'English' library allows us to use more human-readable
## global variables, such as $INPUT_RECORD_SEPARATOR instead of $/,
## which enhances code clarity and makes it easier to understand
## the purpose of these variables in our code.
##===========================================================================##
module ImmosquareYaml
  extend SharedMethods

  class << self




    ##===========================================================================##
    ## Gem configuration
    ##===========================================================================##
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      yield(configuration)
    end

    ##===========================================================================##
    ## This method cleans a specified YAML file by processing it line by line.
    ## It executes a comprehensive cleaning routine, which involves parsing the
    ## YAML content to a hash, optionally sorting it, and then dumping it back
    ## to a YAML format.
    ##
    ## Params:
    ## +file_path+:: Path to the YAML file that needs to be cleaned.
    ## +options+:: A hash of options where :sort controls whether the output should be sorted (default is true).
    ##
    ## Returns:
    ## Boolean indicating the success (true) or failure (false) of the operation.
    ##===========================================================================##
    def clean(file_path, **options)
      ##============================================================##
      ## Default options
      ##============================================================##
      options = {
        :sort   => true,
        :output => file_path
      }.merge(options)

      begin
        output_file_path = nil
        raise("File not found") if !File.exist?(file_path)

        ##===========================================================================##
        ## Setup variables
        ##===========================================================================##
        output_file_path = options[:output]

        ##===========================================================================##
        ## Backup original content for restoration after parsing if necessary
        ##===========================================================================##
        original_content = File.read(file_path) if output_file_path != file_path

        ##===========================================================================##
        ## The cleaning procedure is initialized with a comprehensive clean, transforming
        ## the YAML content to a hash to facilitate optional sorting, before
        ## rewriting it to the YAML file in its cleaned and optionally sorted state.
        ##===========================================================================##
        clean_yml(file_path)
        parsed_yml = parse(file_path)
        parsed_yml = parsed_yml.sort_by_key
        parsed_yml = dump(parsed_yml)

        ##===========================================================================##
        ## Restore original content if necessary
        ##===========================================================================##
        File.write(file_path, original_content) if output_file_path != file_path

        ##===========================================================================##
        ## Write the cleaned YAML content to the specified output file
        ##===========================================================================##
        FileUtils.mkdir_p(File.dirname(output_file_path))
        File.write(output_file_path, parsed_yml)
        true
      rescue StandardError => e
        ##===========================================================================##
        ## Restore original content if necessary
        ##===========================================================================##
        File.write(file_path, original_content) if output_file_path != file_path && !original_content.nil?
        puts(e.message)
        puts(e.backtrace)
        false
      end
    end

    ##==========================================================================##
    ## This method parses a specified YAML file, carrying out a preliminary
    ## cleaning operation to ensure a smooth parsing process. Following this,
    ## the cleaned file is transformed into a hash, which can optionally be sorted.
    ## It operates under the assumption that the file is properly structured.
    ##
    ## Params:
    ## +file_path+:: Path to the YAML file that needs to be parsed.
    ## +options+:: A hash of options where :sort controls whether the output should be sorted (default is true).
    ##
    ## Returns:
    ## A hash representation of the YAML file or false if an error occurs.
    ##==========================================================================##
    def parse(file_path, **options)
      options = {:sort => true}.merge(options)

      begin
        original_content = nil
        raise("File not found") if !File.exist?(file_path)

        ##===========================================================================##
        ## Backup original content for restoration after parsing
        ##===========================================================================##
        original_content = File.read(file_path)

        ##===========================================================================##
        ## clean the file
        ##===========================================================================##
        clean_yml(file_path)

        ##===========================================================================##
        ## parse the file & sort if necessary
        ##===========================================================================##
        parsed_xml = parse_xml(file_path)
        parsed_xml = parsed_xml.sort_by_key if options[:sort]

        ##===========================================================================##
        ## Restore original content
        ##===========================================================================##
        File.write(file_path, original_content) if !original_content.nil?

        ##===========================================================================##
        ## Return the parsed YAML file
        ##===========================================================================##
        parsed_xml
      rescue StandardError => e
        ##===========================================================================##
        ## Restore original content
        ##===========================================================================##
        File.write(file_path, original_content) if !original_content.nil?
        puts(e.message)
        false
      end
    end

    ##===========================================================================##
    ## This method performs a dump operation to obtain a well-structured
    ## YAML file from a hash input. It iterates through each key-value pair in the
    ## hash and constructs a series of lines representing the YAML file, with
    ## appropriate indentations and handling of various value types including
    ## strings with newline characters.
    ##
    ## Params:
    ## +hash+:: The input hash to be converted into a YAML representation.
    ## +lines+:: An array to hold the constructed lines (default is an empty array).
    ## +indent+:: The current indentation level (default is 0).
    ##
    ## Returns:
    ## A string representing the YAML representation of the input hash.
    ##===========================================================================##
    def dump(hash, lines = [], indent = 0)
      hash.each do |key, value|
        ##===========================================================================##
        ## Preparing the key with the proper indentation before identifying
        ## the type of the value to handle it appropriately in the YAML representation.
        ##===========================================================================##
        line = "#{SPACE * indent}#{clean_key(key)}:"

        case value
        when nil
          lines << "#{line} null"
        when String
          if value.include?(NEWLINE) || value.include?('\n')
            ##=============================================================##
            ## We display the line with the key
            ## then the indentation if necessary
            ## then - if necessary (the + is not displayed because it is
            ## the default behavior)
            ##=============================================================##
            line        += "#{SPACE}|"
            indent_level = value[/\A */].size
            line        += (indent_level + INDENT_SIZE).to_s if indent_level > 0
            line        += "-" if !value.end_with?(NEWLINE)
            lines << line

            ##============================================================##
            ## Remove quotes surrounding the value if they are present.
            ## They are not necessary in this case after | or |-
            ##============================================================##
            value = value[1..-2] while (value.start_with?(DOUBLE_QUOTE) && value.end_with?(DOUBLE_QUOTE)) || (value.start_with?(SIMPLE_QUOTE) && value.end_with?(SIMPLE_QUOTE))


            ##=============================================================##
            ## We parse on the 2 types of line breaks
            ##=============================================================##
            value.split(/\\n|\n/).each do |subline|
              lines << "#{SPACE * (indent + INDENT_SIZE)}#{subline}"
            end
          else
            line += "#{SPACE}#{value}"
            lines << line
          end
        when Hash
          lines << line
          dump(value, lines, indent + INDENT_SIZE)
        end
      end

      ##===========================================================================##
      ## Finalizing the construction by adding a newline at the end and
      ## removing whitespace from empty lines.
      ##===========================================================================##
      lines += [NOTHING]
      lines = lines.map {|l| l.strip.empty? ? NOTHING : l }
      lines.join("\n")
    end


    private

    ##===========================================================================##
    ## This method ensures the file ends with a single newline, facilitating
    ## cleaner multi-line blocks. It operates by reading all lines of the file,
    ## removing any empty lines at the end, and then appending a newline.
    ## This guarantees the presence of a newline at the end, and also prevents
    ## multiple newlines from being present at the end.
    ##
    ## Params:
    ## +file_path+:: The path to the file to be normalized.
    ##
    ## Returns:
    ## The total number of lines in the normalized file.
    ##===========================================================================##
    def normalize_last_line(file_path)
      end_of_line = $INPUT_RECORD_SEPARATOR
      ##============================================================##
      ## Read all lines from the file
      ## https://gist.github.com/guilhermesimoes/d69e547884e556c3dc95
      ##============================================================##
      content = File.read(file_path)


      ##===========================================================================##
      ## Remove all trailing empty lines at the end of the file
      ##===========================================================================##
      content.gsub!(/#{Regexp.escape(end_of_line)}+\z/, "")

      ##===========================================================================##
      ## Append an EOL at the end to maintain the file structure
      ##===========================================================================##
      content << end_of_line

      ##===========================================================================##
      ## Write the modified lines back to the file
      ##===========================================================================##
      File.write(file_path, content)

      ##===========================================================================##
      ## Return the total number of lines in the modified file
      ##===========================================================================##
      content.lines.size
    end

    ##============================================================##
    ## Deeply cleans the specified YAML file
    ##============================================================##
    def clean_yml(file_path)
      lines             = []
      inblock_indent    = nil
      weirdblock_indent = nil
      inblock           = false
      weirdblock        = false
      inlist            = false
      line_index        = 1

      ##===================================================================================#
      ## First, we normalize the file by ensuring it always ends with an empty line
      ## This also allows us to get the total number of lines in the file,
      ## helping us to determine when we are processing the last line
      ###===================================================================================#
      line_count = normalize_last_line(file_path)


      File.foreach(file_path) do |current_line|
        last_line = line_index == line_count

        ##===================================================================================#
        ## Cleaning the current line by removing multiple spaces occurring after a non-space character
        ##===================================================================================#
        current_line = current_line.to_s.gsub(/(?<=\S)\s+/, SPACE)

        ##============================================================##
        ## Trimming potential whitespace characters from the end of the line
        ##============================================================##
        current_line = current_line.rstrip

        ##===================================================================================#
        ## Detecting blank lines to specially handle the last line within a block;
        ## if we are inside a block or it's the last line, we avoid skipping
        ##===================================================================================#
        blank_line = current_line.gsub(NEWLINE, NOTHING).empty?
        next if !(last_line || inblock || !blank_line)

        ##============================================================##
        ## Identifying the indentation level of the current line
        ##============================================================##
        last_inblock                 = inblock
        indent_level                 = current_line[/\A */].size
        need_to_clean_prev_inblock   = inblock    == true && ((!blank_line && indent_level <= inblock_indent) || last_line)
        need_to_clen_prev_weirdblock = weirdblock == true && (indent_level <= weirdblock_indent || last_line)

        ##===================================================================================#
        ## Handling the exit from a block:
        ## if we are exiting a block, we clean the entire block
        ##===================================================================================#
        if need_to_clean_prev_inblock
          inblock = false
          ##============================================================##
          ## Extracting the entire block by tracing back lines until we find a lesser indentation
          ## Subsequently determining the type of block we are in and clean accordingly
          ##============================================================##
          i            = -1
          block_indent = lines[i][/\A */].size
          block_lines  = [lines[i].lstrip]
          while lines[i][/\A */].size == lines[i - 1][/\A */].size
            block_lines << lines[i - 1].lstrip
            i -= 1
          end

          ##============================================================##
          ## Handling different types of blocks (literal blocks "|",
          ## folded blocks ">", etc.)
          ## and applying the respective formatting strategies based on
          ## block type and additional indent specified
          ##
          ## | => Literal blocks: It keeps line breaks as
          ## that they are given in the text block.
          ## Final new line: A new line is added to the
          ## end of text.
          ## |- => Literal blocks: It keeps line breaks as
          ## that they are given in the text block.
          ## New final line: The final line break is deleted,
          ## unlike the option |
          ## > Folded blocks: It replaces each new line with a space,
          ## transforming the block of text into a single line.
          ## However, it preserves newlines that follow an empty line.
          ## Final new line: A new line is added at the end of the text.
          ## ===
          ## We can also have |4- or |4+ to say with indentation 4
          ##============================================================##
          block_lines  = block_lines.reverse
          block_type   = lines[i - 1].split(": ").last
          indent_suppl = block_type.scan(/\d+/).first.to_i
          indent_suppl = indent_suppl > 0 ? indent_suppl - INDENT_SIZE : 0
          case block_type[0]
          when  ">"
            lines[i - 1] = lines[i - 1].gsub(">", "|")
            lines[i]     = "#{SPACE * (block_indent + indent_suppl)}#{clean_value(block_lines.join(SPACE))}"
            ((i + 1)..-1).to_a.size.times { lines.pop }
          else
            split = clean_value(block_lines.join(NEWLINE), false).split(NEWLINE)
            (i..-1).each do |ii|
              lines[ii] = "#{SPACE * (block_indent + indent_suppl)}#{split.shift}"
            end
          end
        end

        ##===================================================================================#
        ## Handling 'weirdblocks': cases where multi-line values are enclosed in quotes,
        ## which should actually be single-line values
        ##  key: "
        ##    line1
        ##    line2
        ##    line3"
        ##  key: '
        ##    line1
        ##    line2
        ##    line3'
        ##============================================================##
        if need_to_clen_prev_weirdblock
          weirdblock  = false
          key, value  = lines[-1].split(":", 2)
          lines[-1]   = "#{key}: #{clean_value(value)}"
        end

        ##===================================================================================#
        ## Handling keys without values: if the previous line ends with a colon (:) and is not
        ## followed by a value, we assign 'null' as the value
        ##===================================================================================#
        if inblock == false && weirdblock == false && inlist == false && lines[-1] && lines[-1].end_with?(":") && last_inblock == false
          prev_indent = lines[-1][/\A */].size
          lines[-1] += " null" if prev_indent >= indent_level
        end

        ##============================================================##
        ## Splitting the current line into key and value parts for further processing
        ## You have to split on ":" and not on ": " because we don't have a space when it's
        ## just a key.. but we have a newline
        ## fr: => ["fr", "\n"]
        ##============================================================##
        split = inblock || weirdblock || inlist ? [current_line] : current_line.strip.split(":", 2)
        key   = inblock || weirdblock || inlist ? nil : split[0].to_s.strip

        ##===================================================================================#
        ## Line processing based on various conditions such as being inside a block,
        ## starting with a comment symbol (#), or being a part of a 'weirdblock'
        ## Each case has its specific line cleaning strategy
        ## ----
        ## If the line is commented out, we keep and we remove newlines
        ##============================================================##
        if current_line.lstrip.start_with?("#")
          lines << current_line.gsub(NEWLINE, NOTHING)
        ##================================================= ============##
        ## If is in a block (multiline > | or |-), we clean
        ## the line because it can start with spaces tabs etc.
        ## and put it with the block indenter
        ##================================================= ============##
        elsif inblock == true
          current_line = current_line.gsub(NEWLINE, NOTHING).strip
          lines << "#{SPACE * (inblock_indent + INDENT_SIZE)}#{current_line}"
        ##================================================= ============##
        ## if the line ends with a multi-line character and we have a key.
        ## we start a block
        ## The regex works as follows:
        ##=========================================================
        ## \S+    : All non-space characters at the start of the line.
        ## :      : Matches the string ": " literally (space included).
        ## [>|]   : Matches a single character that is either ">" or "|".
        ## (\d*)  : Capture group that matches zero or more digits (0-9).
        ## [-+]?  : Matches zero or a character that is either "-" or "+".
        ## $      : Matches the end of the line/string.
        ##================================================= ============##
        elsif current_line.rstrip.match?(/\S+: [>|](\d*)[-+]?$/)
          lines << current_line.gsub(NEWLINE, NOTHING)
          inblock_indent = indent_level
          inblock        = true
        ##============================================================##
        ## We are in the scenario of a multiline block
        ## but without > | or |- at the end of the line
        ## which should actually be inline.
        ## mykey:
        ##   line1
        ##   line2
        ##   line3
        ## my key: line1 line2 line3
        ##============================================================##
        elsif split.size < 2
          lines[-1] = (lines[-1] + " #{current_line.lstrip}").gsub(NEWLINE, NOTHING)
        ##============================================================##
        ## Otherwise we are in the case of a classic line
        ## key: value or key: without value
        ##============================================================##
        else
          key           = clean_key(key)
          spaces        = (SPACE * indent_level).to_s
          current_line  = "#{spaces}#{key}:"

          if !split[1].empty?
            value = split[1].to_s.strip

            ##============================================================##
            ## We are in a multiline block which should be an inline
            ## if the value starts with a " and the number of " is odd
            ##============================================================##
            if (value.start_with?(DOUBLE_QUOTE) && value.count(DOUBLE_QUOTE).odd?) || (value.start_with?(SIMPLE_QUOTE) && value.count(SIMPLE_QUOTE).odd?)
              weirdblock        = true
              weirdblock_indent = indent_level
            else
              value = clean_value(split[1])
            end
            current_line += " #{value}"
          end

          ##============================================================##
          ## Merging the cleaned key and value to form the cleaned row
          ##============================================================##
          lines << current_line
        end

        ##============================================================##
        ## We increment the line number
        ##============================================================##
        line_index += 1
      end

      ##============================================================##
      ## We finish the file with a newline and we delete
      ## spaces on "empty" lines + double spaces
      ## with the same technique as above
      ##============================================================##
      lines += [NOTHING]
      lines = lines.map {|l| (l.strip.empty? ? NOTHING : l).to_s.gsub(/(?<=\S)\s+/, SPACE) }
      File.write(file_path, lines.join(NEWLINE))
    end

    ##============================================================##
    ## clean_key Function
    ## Purpose: Clean up and standardize YAML keys
    ##============================================================##
    ## Strategy:
    ## 1. Forcefully convert the key to a string to handle gsub operations, especially if it's an integer.
    ## 2. Remove quotes if they are present.
    ## 3. Check if the key is an integer.
    ## 4. Re-add quotes if the key is a reserved word or an integer.
    ##
    ## This allows us to fetch the string without the surrounding quotes.
    ##============================================================##
    def clean_key(key)
      ##============================================================##
      ## Convert key to string to avoid issues with gsub operations
      ##============================================================##
      key = key.to_s

      ##============================================================##
      ## Remove surrounding quotes from the key
      ##============================================================##
      key = key[1..-2] if (key.start_with?(DOUBLE_QUOTE) && key.end_with?(DOUBLE_QUOTE)) || (key.start_with?(SIMPLE_QUOTE) && key.end_with?(SIMPLE_QUOTE))

      ##============================================================##
      ## Check if the key is an integer
      ##============================================================##
      is_int = key =~ /\A[-+]?\d+\z/

      ##============================================================##
      ##
      ## Re-add quotes if the key is in the list of reserved keys or is an integer
      ##============================================================##
      key = "\"#{key}\"" if RESERVED_KEYS.include?(key) || is_int
      key
    end

    ##============================================================##
    ## " [apple, orange, 'banana']" => [apple, orange, 'banana']
    ##============================================================##
    def string_in_array(string)
      begin
        string_striped = string.strip
        string_striped[1..-2].split(/,\s?/) if string_striped.match(/^\[.*\]$/)
      rescue StandardError
        nil
      end
    end

    ##============================================================##
    ## clean_value Function
    ## Purpose: Sanitize and standardize YAML values
    ## In YAML "inblock" scenarios, there's no need to add quotes
    ## around values as it's inherently handled.
    ## ============================================================ ##
    def clean_value(values, with_quotes_verif = true)
      ##============================================================##
      ## Convert key to array if not
      ## fruits: [apple, orange, 'banana']
      ## demo: "demo"
      ##============================================================##
      is_array = string_in_array(values)
      values   = is_array.nil? ? [values] : is_array



      values = values.map do |value|
        ##============================================================##
        ## Convert value to string to prevent issues in subsequent operations
        ##============================================================##
        value = value.to_s

        ##============================================================##
        ## Remove newline characters at the end of the value if present.
        ## This should be done prior to strip operation to handle scenarios
        ## where the value ends with a space followed by a newline.
        ###============================================================##
        value = value[0..-2] if value.end_with?(NEWLINE)


        ##============================================================##
        ## Clean up the value:
        ## - Remove tabs, carriage returns, form feeds, and vertical tabs.
        ## \t: corresponds to a tab
        ## \r: corresponds to a carriage return
        ## \f: corresponds to a form feed
        ## \v: corresponds to a vertical tab
        ## We keep the \n
        ##============================================================##
        value = value.gsub(/[\t\r\f\v]+/, NOTHING)

        ##============================================================##
        ## Replace multiple spaces with a single space.
        ##============================================================##
        value = value.gsub(/ {2,}/, SPACE)

        ##============================================================##
        ## Trim leading and trailing spaces.
        ##============================================================##
        value = value.strip

        ##============================================================##
        ## Replace special quotes with standard single quotes.
        ##============================================================##
        value = value.gsub(WEIRD_QUOTES_REGEX, SIMPLE_QUOTE)

        ##============================================================##
        ## Remove all quotes surrounding the value if they are present.
        ## They will be re-added later if necessary.
        ## """"value"""" => value
        ##============================================================##
        value = value[1..-2] while (value.start_with?(DOUBLE_QUOTE) && value.end_with?(DOUBLE_QUOTE)) || (value.start_with?(SIMPLE_QUOTE) && value.end_with?(SIMPLE_QUOTE))

        ##============================================================##
        ## Convert emoji representations such as \U0001F600 to their respective emojis.
        ##============================================================##
        value = value.gsub(/\\U([0-9A-Fa-f]{8})/) { [::Regexp.last_match(1).to_i(16)].pack("U*") }

        ##=============================================================##
        ## Handling cases where the value must be surrounded by quotes
        ## if:
        ## management of "" and " ". Not possible to have more spaces
        ## because we have already removed the double spaces
        ## else
        ## value.include?(": ")                   => key: text with: here
        ## value.include?(" #")                   => key: text with # here
        ## value.include?(NEWLINE)                => key: Line 1\nLine 2\nLine 3
        ## value.include?('\n')                   => key: Line 1"\n"Line 2"\n"Line 3
        ## value.start_with?(*YML_SPECIAL_CHARS)  => key: @text
        ## value.end_with?(":")                   => key: text:
        ## RESERVED_KEYS.include?(value)          => key: YES
        ## value.start_with?(SPACE)               => key: 'text'
        ## value.end_with?(SPACE)                 => key: text '
        ##=============================================================##
        if value.empty?
          value = "\"#{value}\""
        elsif with_quotes_verif == true
          value = "\"#{value}\"" if value.include?(": ") ||
                                    value.include?(" #") ||
                                    value.include?(NEWLINE) ||
                                    value.include?('\n') ||
                                    value.start_with?(*YML_SPECIAL_CHARS) ||
                                    value.end_with?(":") ||
                                    (is_array ? false : RESERVED_KEYS.include?(value)) ||
                                    value.start_with?(SPACE) ||
                                    value.end_with?(SPACE)
        end
        value
      end
      is_array ? "[#{values.join(", ")}]" : values.first
    end

    ##============================================================##
    ## parse_xml Function
    ## Purpose: Parse an XML file into a nested hash representation.
    ##
    ## This method reads through the XML file line by line and creates a
    ## nested hash representation based on the structure and content of the XML.
    ##============================================================##
    def parse_xml(file_path)
      nested_hash = {}
      inblock     = nil
      last_keys   = []

      ##============================================================##
      ## We go over each line of the file to create a hash.
      ## We put the multiline blocks in an array to recover
      ## all the values and the formatting type then we will pass
      ## on each of these arrays subsequently to transform them
      ## in the corresponding string
      ##============================================================##
      File.foreach(file_path) do |line|
        ##============================================================##
        ## Determine the indentation level of the line.
        ##============================================================##
        indent_level = line[/\A */].size

        ##============================================================##
        ## Check for blank lines (which can be present within multi-line blocks)
        ##============================================================##
        blank_line = line.gsub(NEWLINE, NOTHING).empty?

        ##============================================================##
        ## Split the line into key and value.
        ##============================================================##
        split   = line.strip.split(":", 2)
        key     = split[0].to_s.strip
        inblock = nil if !inblock.nil? && !blank_line && indent_level <= inblock


        ##============================================================##
        ## Set the key level based on indentation
        ##============================================================##
        last_keys = last_keys[0, (blank_line ? inblock + INDENT_SIZE : indent_level) / INDENT_SIZE]

        ##============================================================##
        ## If inside a multi-line block, append the line to the current key's value
        ##============================================================##
        if !inblock.nil?
          current_key           = last_keys.last
          parent_keys           = last_keys[0..-2]
          result                = parent_keys.reduce(nested_hash) {|hash, k| hash[k] }
          result[current_key][1] << line.strip
        ##============================================================##
        ## Handle multi-line key declarations.
        ## We no longer have the >
        ## because it is transformed in the clean_xml into |
        ##============================================================##
        elsif line.gsub("#{key}:", NOTHING).strip.start_with?("|")
          inblock     = indent_level
          block_type  = line.gsub("#{key}:", NOTHING).strip
          result      = last_keys.reduce(nested_hash) {|hash, k| hash[k] }
          result[key] = [block_type, []]
          last_keys << key
        ##============================================================##
        ## Handle regular key-value pair declarations
        ##============================================================##
        else
          value  = split[1].to_s.strip
          result = last_keys.reduce(nested_hash) {|hash, k| hash[k] }
          if value.empty?
            result[key] = {}
            last_keys << key
          else
            result[key] = value.strip == "null" ? nil : value
          end
        end
      end

      ##============================================================##
      ## We go over each value then we process if it is a has
      ## | with final newline
      ## |4 with newline and indentation of 4
      ## |- without newline
      ## |4- without newline and indentation of 4
      ##============================================================##
      deep_transform_values(nested_hash) do |value|
        if value.is_a?(Array)
          style_type   = value[0]
          indent_supp  = style_type.scan(/\d+/).first&.to_i || 0
          indent_supp  = [indent_supp - INDENT_SIZE, 0].max
          value[1]     = value[1].map {|l| "#{SPACE * indent_supp}#{l}" }
          text         = value[1].join(NEWLINE)
          modifier     = style_type[-1]

          case modifier
          when "+"
            text << NEWLINE unless text.end_with?(NEWLINE)
          when "-"
            text.chomp!
          else
            text << NEWLINE unless text.end_with?(NEWLINE)
          end
          text
        else
          value
        end
      end
    end


  end
end
