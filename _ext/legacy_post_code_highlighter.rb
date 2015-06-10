##
#
# An extension of type transformer which modifies posts using the legacy syntax highlighting by replacing affected
# <pre> blocks with an equivalent <pre> highlighted by CodeRay.
#
##
module InRelationTo
  module Extensions
    class LegacyPostCodeHighlightingTransformer

      def transform(site, page, input)

        ext = File.extname(page.output_path)
        if !ext.empty?
          ext_txt = ext[1..-1]
          if ext_txt == "html"

            # Replace all <pre> blocks looking like this:
            # <pre brush: java">...</pre>
            while input =~ /(<pre.*?brush:\s*java.*?>)((.|\n)*?)(<\/pre>)/ do
              listing = $2.gsub(/&#x000A;/, "\n")
              listing.gsub!(/&gt;/, ">")
              listing.gsub!(/&lt;/, "<")
              listing = CodeRay.scan( listing, :java).html
              listing = '<div class="listingblock"><div class="content"><pre class="CodeRay highlight"><code data-lang="Java">' + listing + "</code></pre></div></div>"
              input.sub!(/<pre.*?brush:\s*java.*?>(.|\n)*?<\/pre>/, listing)
            end

            # Replace all <pre> blocks looking like this:
            # <pre brush: xml">...</pre>
            while input =~ /(<pre.*?brush:\s*xml.*?>)((.|\n)*?)(<\/pre>)/ do
              listing = $2.gsub(/&#x000A;/, "\n")

              listing.gsub!(/&gt;/, ">")
              listing.gsub!(/&lt;/, "<")
              listing = CodeRay.scan( listing, :xml).html
              listing = '<div class="listingblock"><div class="content"><pre class="CodeRay highlight"><code data-lang="XML">' + listing + "</code></pre></div></div>"
              input.sub!(/<pre.*?brush:\s*xml.*?>(.|\n)*?<\/pre>/, listing)
            end
          end
        end

        input
      end
    end
  end
end