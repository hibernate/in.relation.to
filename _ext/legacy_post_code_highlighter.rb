##
#
# An extension of type transformer which modifies posts using the legacy syntax highlighting by replacing affected
# <pre> blocks with an equivalent <pre> highlighted by CodeRay.
#
# The extension can be disabled by setting legacy_post_syntax_highlighting: disabled for a given profile. By default it
# is enabled.
#
##
module InRelationTo
  module Extensions
    class LegacyPostCodeHighlightingTransformer

      def transform(site, page, input)
        if !site.legacy_post_syntax_highlighting.nil? and !site.legacy_post_syntax_highlighting.to_s.eql?('enabled')
          return input
        end

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