module ImmosquareYaml
  ##============================================================##
  ## Delete — removes one or more dot-paths from an i18n YAML
  ## file and re-emits it through the standard dump pipeline
  ## (sort, quoting, literal blocks). Empty parent Hashes left
  ## behind by a deletion are pruned recursively so the YAML
  ## doesn't keep dangling empty maps.
  ##
  ## Path quoting follows the same convention as flatten_keys /
  ## parse_path : reserved (yes/no/true/...) and purely numeric
  ## segments must be wrapped in "..." inside the dot-path.
  ##============================================================##
  class << self

    ##============================================================##
    ## delete_paths(file_path, paths, sort: true, output: file_path)
    ##
    ## paths : a single dot-path String or an Array<String>.
    ##
    ## Returns a Hash :
    ##   { :deleted   => [paths actually removed],
    ##     :not_found => [paths that did not exist in the file] }
    ##
    ## Returns false if the file cannot be parsed or if its root
    ## node is not a Hash (i18n YAML files are always mappings).
    ##
    ## Note : the file is always rewritten through `dump`, even when
    ## every path is reported as :not_found. This means calling
    ## `delete_paths` doubles as a `clean` (sort + reformat) on the
    ## target file. Use `:output => "..."` to write elsewhere.
    ##============================================================##
    def delete_paths(file_path, paths, **options)
      options = {
        :sort   => true,
        :output => file_path
      }.merge(options)

      begin
        raise("File not found") if !File.exist?(file_path)

        parsed = parse(file_path, :sort => options[:sort])
        return false if parsed == false || !parsed.is_a?(Hash)

        paths     = Array(paths)
        deleted   = []
        not_found = []

        ##============================================================##
        ## Walk each dot-path, delete the leaf if present, prune
        ## empty parents on the way back up.
        ##============================================================##
        paths.each do |dot_path|
          segments = parse_path(dot_path)
          if !segments.empty? && delete_at_segments(parsed, segments)
            deleted << dot_path
          else
            not_found << dot_path
          end
        end

        output = dump(parsed)
        FileUtils.mkdir_p(File.dirname(options[:output]))
        File.write(options[:output], output)

        {:deleted => deleted, :not_found => not_found}
      rescue StandardError => e
        puts(e.message)
        puts(e.backtrace)
        false
      end
    end


    private


    ##============================================================##
    ## Recursive segment walker. Returns true if a leaf was
    ## actually removed. On the way back up, an intermediate Hash
    ## that has become empty is pruned from its parent so the
    ## final YAML doesn't keep dangling empty maps.
    ##============================================================##
    def delete_at_segments(hash, segments)
      return false if !hash.is_a?(Hash)

      head, *rest = segments
      return false if !hash.key?(head)

      if rest.empty?
        hash.delete(head)
        return true
      end

      child   = hash[head]
      removed = delete_at_segments(child, rest)
      hash.delete(head) if removed && child.is_a?(Hash) && child.empty?
      removed
    end

  end
end
