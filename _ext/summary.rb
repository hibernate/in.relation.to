require 'nokogiri'

module InRelationTo
  module Extensions
    class Summary

      def initialize(post_items_property)
        @post_items_property = post_items_property
      end

      def execute(site)
        posts = site.send( @post_items_property )
        posts.each do |post|
          post.summary = extract_summary(post.content.force_encoding("UTF-8"))
          if !post.description
            description_html = Nokogiri::HTML::fragment(post.summary)
            description_html.search('p,div,br').each{ |e| e.after "\n" }
            post.description = description_html.content
          end
        end
      end

      def extract_summary( post_content )
        post_document_fragment = Nokogiri::HTML::fragment(post_content)

        manual_cut = post_content.include? '<!-- more -->'

        summary = ''

        i = 0
        post_document_fragment.children.each do |html_node|
          if html_node.is_a?(Nokogiri::XML::Text) || html_node.is_a?(Nokogiri::XML::Comment)
            next
          end
          if html_node.name == 'div' && html_node.attribute('id') && html_node.attribute('id').value == 'preamble'
            section_body = html_node.xpath('div[@class="sectionbody"]').first
            if section_body
              section_body_children = section_body.xpath('div')
              break unless section_body_children.each do |element|
                if manual_cut
                  element_xhtml = element.to_xhtml
                  if element_xhtml.include? '<!-- more -->'
                    break
                  else
                    summary = summary << element_xhtml
                  end
                else
                  if element.attribute('class').value == 'paragraph' || element.attribute('class').value == 'ulist'
                    summary = summary << element.to_xhtml
                  else
                    summary = summary << '<p>[ ... ]</p>'
                    break
                  end
                  i += 1
                  if section_body_children.length > 5 && i > 2
                    summary = summary << '<p>[ ... ]</p>'
                    break
                  end
                end
              end
            else
              summary = summary << html_node.to_xhtml
            end
            break
          elsif html_node.name == 'div' && html_node.attribute('class') && (html_node.attribute('class').value == 'paragraph' || html_node.attribute('class').value == 'ulist')
            if manual_cut
              element_xhtml = html_node.to_xhtml
              if element_xhtml.include? '<!-- more -->'
                break
              else
                summary = summary << element_xhtml
              end
            else
              summary = summary << html_node.to_xhtml
              i += 1
              if i > 2
                break
              end
            end
          # old posts
          elsif html_node.name == 'div' && html_node.attribute('id') && html_node.attribute('id').value == 'documentDisplay'
            first_node = html_node.xpath('node()[not(self::text())]').first
            if first_node && first_node.name == 'p'
              summary = first_node.to_xhtml
            end
            break
          else
            break
          end
        end
        summary
      end
    end
  end
end
