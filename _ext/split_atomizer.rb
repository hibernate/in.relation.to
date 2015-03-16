# Generic version of Tagger
module Awestruct
  module Extensions
    class SplitAtomizer

      def initialize(split_items_property, split_property, output_path, opts={})
        @split_items_property = split_items_property
        @split_property = split_property
        @output_path = output_path
        @sanitize = opts[:sanitize] || false
        @atom_feed_file = opts[:atom_feed_file] || "feed.atom"
      end

      def execute(site)
        @splits = site.send( "#{@split_items_property}_#{@split_property}" )
        filters = site.splitter_filters
        filter_property = filters.send( @split_property ) if not filters.nil?
        whitelist = (filter_property.whitelist_atom if not filter_property.nil?) || Array.new()
        blacklist = (filter_property.blacklist_atom if not filter_property.nil?) || Array.new()
        @splits.each do |split|
          ## Optionally sanitize split URL
          sanitized = sanitize(split.to_s)
          if ( whitelist.empty? or whitelist.include? sanitized ) and not blacklist.include? sanitized
            output_prefix = File.join( @output_path, sanitized )
            atomizer = Awestruct::Extensions::Atomizer.new( @split_items_property, 
                                                         File.join(output_prefix, @atom_feed_file),
                                                         :content_url=>"#{site.base_url}#{output_prefix}",
                                                         :feed_title=>"In Relation To #{split.to_s}" )
            atomizer.execute( site )
          end
        end
      end

      def sanitize(string)
        #replace accents with unaccented version, go lowercase and replace and space with dash
        if @sanitize
          string.to_s.urlize({:convert_spaces=>true})
        else
          string
        end
      end
    end
  end
end
