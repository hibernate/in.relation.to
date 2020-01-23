require 'js_minifier'
require 'css_minifier'
require 'html_minifier'
require 'relative'
require 'redirect_creator'
require 'directory_listing'

# dependencies for asciidoc support
require 'tilt'
require 'haml'
require 'asciidoctor'

# blog
require 'splitter'
require 'split_cloud'
require 'split_filterer'
require 'split_atomizer'
require 'paginator'
require 'posts'
require 'summary'
require 'ignore_old_posts'
require 'date'
require 'i18n'
require 'json_feed_generator'

# custom extensions
require 'legacy_post_code_highlighter'
require 'link_renderer'

I18n.enforce_available_locales = false

# hack to add asciidoc support in HAML
# remove once haml_contrib has accepted the asciidoc registration patch
# :asciidoc
#   some block content
#
# :asciidoc
#   :doctype: inline
#   some inline content
#
if !Haml::Filters.constants.map(&:to_s).include?('AsciiDoc')
  Haml::Filters.register_tilt_filter 'AsciiDoc'
  Haml::Filters::AsciiDoc.options[:safe] = :safe
  Haml::Filters::AsciiDoc.options[:attributes] ||= {}
  Haml::Filters::AsciiDoc.options[:attributes]['notitle!'] = ''
  # copy attributes from site.yml
  attributes = site.asciidoctor[:attributes].each do |key, value|
    Haml::Filters::AsciiDoc.options[:attributes][key] = value
  end
end

Awestruct::Extensions::Pipeline.new do
  # register helpers to be used in templates
  helper Awestruct::Extensions::Partial
  helper Awestruct::Extensions::GoogleAnalytics
  helper Awestruct::Extensions::Relative
  helper Awestruct::Extensions::DirectoryListing

  # data
  extension Awestruct::Extensions::DataDir.new

  # blog

  extension Awestruct::Extensions::Posts.new
  extension Awestruct::Extensions::SplitFilterer.new( :posts,
                                                     'tags',
                                                     :sanitize=>true,
                                                     :blacklist=>['author', 'authors', 'tags', 'tag',
                                                      'page', 'javascripts', 'images', 'readme', 'templates']
                                                    )

  extension InRelationTo::Extensions::IgnoreOldPosts.new :posts
  extension InRelationTo::Extensions::Summary.new :posts

  if Engine.instance.site.profile != 'editor'
    extension InRelationTo::Extensions::Splitter.new( :posts,
                                                   'tags',
                                                   '_templates/tag',
                                                   '',
                                                   :per_page=>10, :per_page_init=>10,
                                                   :output_home_file=>'index',
                                                   :sanitize=>true )
    extension Awestruct::Extensions::SplitCloud.new( :posts,
                                                   'tags',
                                                   '/tags/index.html',
                                                   :title=>'Tags')
    extension InRelationTo::Extensions::Splitter.new( :posts,
                                                   'author',
                                                   '_templates/author',
                                                   '',
                                                   :per_page=>10, :per_page_init=>10,
                                                   :output_home_file=>'index',
                                                   :sanitize=>true )
    extension Awestruct::Extensions::Atomizer.new( :posts,
                                                   '/blog.atom',
                                                   :template=>File.join(File.dirname(__FILE__), '../_templates/template.atom.haml'),
                                                   :feed_title=>'In Relation To Blog')
  end

  extension InRelationTo::Extensions::JsonFeedGenerator.new( :posts, 'feeds', [ 'Hibernate ORM', 'Hibernate Search', 'Hibernate Validator', 'Hibernate OGM', 'JBoss Tools' ], 5)

  extension Awestruct::Extensions::Paginator.new( :posts, 'index', :per_page=>10, :per_page_init=>10 )
  extension InRelationTo::Extensions::PaginationLinkRenderer.new()

  # register extensions and transformers
  transformer Awestruct::Extensions::JsMinifier.new
  transformer Awestruct::Extensions::CssMinifier.new
  transformer Awestruct::Extensions::HtmlMinifier.new
  transformer InRelationTo::Extensions::LegacyPostCodeHighlightingTransformer.new

  extension   Awestruct::Extensions::Indexifier.new

end

# vim: softtabstop=2 shiftwidth=2 expandtab
