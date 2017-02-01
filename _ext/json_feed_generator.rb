require 'awestruct/context_helper'
require 'htmlentities'

module InRelationTo
  module Extensions
    class JsonFeedGenerator

      class TagStat
        attr_accessor :entries
        def initialize(tag, entries)
          @tag   = tag
          @entries = entries
        end

        def to_s
          @tag
        end
      end

      class BlogEntry
        attr_accessor :title, :date, :snippet, :url

        def initialize(title, date, snippet, url)
          @title = title
          @date = date
          @snippet = snippet
          @url = url
        end

        def as_json(options={})
          {
            title: @title,
            date: @date,
            snippet: @snippet,
            url: @url
          }
        end

        def to_json(*options)
          as_json(*options).to_json(*options)
        end
      end

      def initialize(entries, output_path='feeds', tags_to_generate, limit)
        @entries = entries
        @output_path = output_path
        @tags_to_generate = tags_to_generate || {}
        @limit = limit
      end

      def execute(site)
        @tags = {}
        @global_entries = []
        entries = @entries.is_a?(Array) ? @entries : site.send( @entries ) || []
        self.extend( Awestruct::ContextHelper )

        entries.each do |entry|
          feed_entry = site.engine.load_page(entry.source_path, :relative_path => entry.relative_source_path)
          feed_entry.output_path = entry.output_path
          feed_entry.date = feed_entry.timestamp.nil? ? entry.date.xmlschema : feed_entry.timestamp.xmlschema

          if @global_entries.size <= @limit
            @global_entries << BlogEntry.new( HTMLEntities.new.decode( feed_entry.title ), feed_entry.date, HTMLEntities.new.decode( summarize( html_to_text( feed_entry.content ) , 50 ) ), "#{site.base_url}#{feed_entry.output_path.chomp( 'index.html' )}" )
          end

          tags = entry.tags
          if ( tags && ! tags.empty? )
            tags.each do |tag|
              tag = tag.to_s
              next if ( !@tags_to_generate.include?(tag) || ( @tags.has_key?(tag) && @tags[tag].entries.size > @limit ) )
              @tags[tag] ||= TagStat.new( tag, [] )
              @tags[tag].entries << BlogEntry.new( feed_entry.title, feed_entry.date, "#{summarize( html_to_text( feed_entry.content ), 50 )}", "#{site.base_url}#{feed_entry.output_path.chomp( 'index.html' )}" )
            end
          end
        end

        feed_directory = File.join( site.config.output_dir, @output_path )
        FileUtils.mkdir_p( feed_directory )

        output_file = File.join( feed_directory, "global.json" )
        File.open(output_file, 'w') do |f|
          f.puts "getBlogEntries(#{@global_entries.to_json})"
        end
        @tags_to_generate.each do |tag|
          if @tags.has_key?(tag)
            output_file = File.join( feed_directory, "#{tag.to_s.urlize({:convert_spaces=>true})}.json" )
            File.open(output_file, 'w') do |f|
              f.puts "getBlogEntries(#{@tags[tag].entries.to_json})"
            end
          end
        end
      end
    end
  end
end
