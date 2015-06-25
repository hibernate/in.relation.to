##
#
# An extension which renders the post links using the Twitter Bootstrap pagination styles. Requires the default
# pagination extension to be enabled.
#
##
module InRelationTo
  module Extensions
    class PaginationLinkRenderer

      module BootstrapPaginationLinkRenderer

        def bootstrap_links
          html = %Q(<div class="pagination">)
          html += %Q(<ul>)
          if !previous_page.nil?
            html += %Q(<li><a href="#{previous_page.url}">&laquo;</a></li>)
          else
            html += %Q(<li class="disabled"><a href="#">&laquo;</a></li>)
          end
          first_skip = false
          second_skip = false
          pages.each_with_index do |page, i|
            if ( i == current_page_index )
              html += %Q(<li class="active"><a href="#">#{i+1}</a></li> )
            elsif ( i <= window )
              html += %Q(<li><a href="#{page.url}" class="page-link">#{i+1}</a></li> )
            elsif ( ( i > window ) && ( i < ( current_page_index - window ) ) && ! first_skip  )
              html += %Q(<li class="disabled"><a href="#">...</a></li>)
              first_skip = true
            elsif ( ( i > ( current_page_index + window ) ) && ( i < ( ( pages.size - window ) - 1 ) ) && ! second_skip )
              html += %Q(<li class="disabled"><a href="#">...</a></li>)
              second_skip = true
            elsif ( ( i >= ( current_page_index - window ) ) && ( i <= ( current_page_index + window ) ) )
              html += %Q(<li><a href="#{page.url}">#{i+1}</a></li> )
            elsif ( i >= ( ( pages.size - window ) - 1 ) )
              html += %Q(<li><a href="#{page.url}">#{i+1}</a></li> )
            end
          end
          if !next_page.nil?
            html += %Q(<li><a href="#{next_page.url}">&raquo;</a></li> )
          else
            html += %Q(<li class="disabled"><a href="#">&raquo;</a></li> )
          end
          html += %Q(</ul>)
          html += %Q(</div>)
          html
        end
      end

      def execute(site)
        site.pages.each do |page|
          page.posts.extend( BootstrapPaginationLinkRenderer )
        end
      end

    end
  end
end
