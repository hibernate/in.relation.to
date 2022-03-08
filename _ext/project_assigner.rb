# Assigns project to page based on tags

module InRelationTo
  module Extensions
    class ProjectAssigner

      TAG_TO_PROJECT = {
        'Hibernate ORM' => 'orm',
        'Hibernate Search' => 'search',
        'Hibernate Validator' => 'validator',
        'Hibernate OGM' => 'ogm',
        'Hibernate Reactive' => 'reactive',
        'Hibernate Tools' => 'tools'
      }

      def execute(site)
        @splits ||= {}
        all = site.send( :posts )
        return if ( all.nil? || all.empty? )

        all.each do |page|
          tags = page.send( 'tags' )
          if ( tags && ! tags.empty? )
            # in first pass, transformed into an array
            if not tags.kind_of?(Array)
              tags = [tags]
            end

            page.project = tags&.map { |tag| TAG_TO_PROJECT[tag] } .find { |project| project != nil }
          end
        end
      end
    end
  end
end
