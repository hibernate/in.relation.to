module InRelationTo
  module Extensions
    class IgnoreOldPosts

      def initialize(post_items_property)
        @post_items_property = post_items_property
      end

      def execute(site)
        ignore_older_than_days = site.ignore_older_than_days
        ignore_older_than=nil

        if !ignore_older_than_days.nil? && ignore_older_than_days.to_i > 0
          ignore_older_than = Time.now - ignore_older_than_days.to_i * 24 * 60 * 60
        else
          return
        end

        pages = site.pages
        posts = site.send( @post_items_property )

        posts_to_remove = []
        posts.each do |post|
          if !post.date.nil? && post.date < ignore_older_than
            posts_to_remove << post
          end
        end

        if !posts_to_remove.empty?
          posts_to_remove.each do |post|
            pages.delete( post )
            posts.delete( post )
          end

          print "Ignored #{posts_to_remove.length} older posts in order to speed up site generation\n"
        end
      end
    end
  end
end
