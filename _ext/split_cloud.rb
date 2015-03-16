
module Awestruct
  module Extensions
    class SplitCloud

      def initialize(split_items_property, split_property, output_path, opts={})
        @split_items_property = split_items_property
        @split_property = split_property
        @output_path = output_path
        @layout = opts[:layout].to_s
        @title  = opts[:title] || 'Tags'
      end

      def execute(site)
        page = site.engine.load_page( File.join( File.dirname( __FILE__ ), 'split_cloud.html.haml' ) )
        page.output_path = File.join( @output_path )
        page.layout = @layout
        page.title  = @title
        page.split_property = @split_property
        page.send( "#{@split_property}=",  site.send( "#{@split_items_property}_#{@split_property}" ) || [] )
        site.pages << page
        site.send( "#{@split_items_property}_#{@split_property}_cloud=", LazyPage.new( page ) )
      end

    end

    class LazyPage
      def initialize(page)
        @page = page
      end
      def to_s
        @page.content
      end
    end

  end
end
