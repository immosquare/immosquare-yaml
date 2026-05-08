module ImmosquareYaml
  ##============================================================##
  ## Flatten — turns one (or several) i18n YAML file(s), or a hash
  ## already in memory, into a list of dot-separated paths pointing
  ## to leaf values.
  ##
  ## Segments matching RESERVED_KEYS (yes/no/true/false/...) or
  ## purely numeric segments are quoted ("true", "42") so they stay
  ## compatible with I18n.t, which would otherwise interpret them
  ## as booleans / integers.
  ##
  ## Array and nil values are treated as leaves (no descent).
  ## Empty Hashes are skipped (no leaf emitted).
  ##============================================================##
  class << self

    ##============================================================##
    ## flatten_keys(input, with_values: false, with_file: false)
    ##
    ## input :
    ##   - Hash             : flattened in memory (no I/O). File
    ##                        column is nil in the resulting tuples.
    ##   - String           : a single YAML file path.
    ##   - Array<String>    : a list of YAML file paths.
    ##
    ## Globs are NOT expanded — the caller is expected to expand
    ## them upstream (e.g. with Dir.glob) and pass an Array<String>.
    ## Mixing a Hash with file paths in the same Array is not
    ## supported.
    ##
    ## No option         → Array<String> sorted + deduplicated
    ## with_values: true → Array<[path, value]> not deduplicated
    ## with_file:   true → adds the source file_path to each entry
    ##                     (nil for Hash inputs)
    ##
    ## Missing / empty / unreadable file: silently ignored.
    ##============================================================##
    def flatten_keys(input, **options)
      options = {
        :with_values => false,
        :with_file   => false
      }.merge(options)

      entries = []

      if input.is_a?(Hash)
        flatten_hash(input, [], entries, nil) if !input.empty?
      else
        paths = input.is_a?(Array) ? input : [input]
        paths.each do |path|
          path = path.to_s
          next if path.empty? || !File.exist?(path)

          parsed = parse(path, :sort => false)
          next if parsed == false || !parsed.is_a?(Hash) || parsed.empty?

          flatten_hash(parsed, [], entries, path)
        end
      end

      format_entries(entries, options)
    end

    ##============================================================##
    ## parse_path(dot_path) → Array<String>
    ##
    ## Symmetric inverse of the quoting done by flatten_keys: splits
    ## on "." and strips wrapping quotes from reserved or numeric
    ## segments. The result can be passed directly to Hash#dig on a
    ## hash returned by ImmosquareYaml.parse.
    ##
    ## Limitation : keys containing a literal "." in their name are
    ## not supported (the path would be split into two segments).
    ##
    ## Examples :
    ##   parse_path("fr.statuses.\"yes\"")  # => ["fr", "statuses", "yes"]
    ##   parse_path("fr.counts.\"42\"")     # => ["fr", "counts", "42"]
    ##   parse_path("fr.app.title")         # => ["fr", "app", "title"]
    ##============================================================##
    def parse_path(dot_path)
      dot_path.to_s.split(".").map {|segment| unquote_segment(segment) }
    end


    private


    ##============================================================##
    ## Recursive walk over the hash. Array and nil are treated as
    ## leaves. Empty Hashes are skipped. Entries are accumulated as
    ## [path, value, file].
    ##============================================================##
    def flatten_hash(node, segments, entries, file_path)
      if node.is_a?(Hash)
        return if node.empty?

        node.each do |key, value|
          flatten_hash(value, segments + [quote_segment(key.to_s)], entries, file_path)
        end
      else
        entries << [segments.join("."), node, file_path]
      end
    end

    ##============================================================##
    ## Quotes a path segment if it matches RESERVED_KEYS or if it
    ## is purely numeric (consistent with clean_key in the dump).
    ##============================================================##
    def quote_segment(segment)
      if SharedMethods::RESERVED_KEYS.include?(segment) || segment.match?(/\A[-+]?\d+\z/)
        "\"#{segment}\""
      else
        segment
      end
    end

    ##============================================================##
    ## Inverse of quote_segment: strips wrapping quotes when the
    ## segment is enclosed in " ... ". Other segments are returned
    ## unchanged.
    ##============================================================##
    def unquote_segment(segment)
      if segment.start_with?("\"") && segment.end_with?("\"") && segment.length >= 2
        segment[1..-2]
      else
        segment
      end
    end

    ##============================================================##
    ## Formats the output according to the options. Without
    ## with_values, paths are deduplicated (useful when flattening
    ## multiple locales sharing the same key). Otherwise, all
    ## entries are kept.
    ##============================================================##
    def format_entries(entries, options)
      if options[:with_values] && options[:with_file]
        entries.sort_by {|path, _value, file| [path, file.to_s] }
      elsif options[:with_values]
        entries.sort_by {|path, _value, file| [path, file.to_s] }
               .map {|path, value, _file| [path, value] }
      elsif options[:with_file]
        entries.map  {|path, _value, file| [path, file] }
               .uniq
               .sort_by {|path, file| [path, file.to_s] }
      else
        entries.map(&:first).uniq.sort
      end
    end

  end
end
