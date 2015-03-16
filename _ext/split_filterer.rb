# Generic version of Tagger
module Awestruct
  module Extensions
    # Filter out a set of split values (like tags).
    # Values are outputted in system out as warning
    # and removed from the post.
    # This extension must be placed right after the Post extension in the
    # pipeline
    class SplitFilterer
      # split_items_property: property containing the posts
      # split_property: name of the property to split by
      def initialize(split_items_property, split_property, opts={})
        @split_items_property = split_items_property
        @split_property = split_property
        @sanitize = opts[:sanitize] || false
        @pagination_opts = opts
        #@whitelist = Array( opts[:whitelist] )
        #@blacklist = Array( opts[:blacklist] )
      end

      def execute(site)
        @splits ||= {}
        all = site.send( @split_items_property )
        return if ( all.nil? || all.empty? ) 

        plural_split_property =  @split_property

        filters = site.splitter_filters
        filter_property = filters.send( @split_property ) if not filters.nil?
        whitelist = (filter_property.whitelist if not filter_property.nil?) || Array.new()
        blacklist = (filter_property.blacklist if not filter_property.nil?) || Array.new()

        all.each do |page|
          splits = page.send( @split_property )
          #to_s.urlize({:convert_spaces=>true})
          if ( splits && ! splits.empty? )
            filtered_out_splits = splits.find_all { |split| blacklist.include? sanitize(split) }
            splits.each do |elt|
              if blacklist.include? elt.to_s
                puts ">>>> WARNING: tag '#{elt.to_s}' is illegal, remove it from: #{page.relative_source_path}"
              end
            end
            filtered_splits = splits.find_all { 
              |split| ( ( whitelist.empty? or whitelist.include? sanitize(split) ) and not (blacklist.include? sanitize(split) ) )
            }
            page.send( "#{@split_property}=", filtered_splits )
          end
        end
      end

      def sanitize(data)
        if @sanitize
          return data.to_s.urlize({:convert_spaces=>true})
        else
          return data.to_s
        end
      end
    end
  end
end
