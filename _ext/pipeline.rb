require 'wget_wrapper'
require 'js_minifier'
require 'css_minifier'
require 'html_minifier'
require 'file_merger'
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
require 'atomizer'
require 'paginator'
require 'posts'


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
  extension Awestruct::Extensions::Posts.new( '', :posts )
  extension Awestruct::Extensions::SplitFilterer.new( :posts,
                                                     'tags',
                                                     :sanitize=>true,
                                                     :blacklist=>['author', 'authors', 'tags', 'tag',
                                                      'page', 'javascripts', 'images', 'readme', 'templates']
                                                    ) 

  editor = Engine.instance.site.profile == 'editor'
  pagination = 10
  if editor
    # make very few paginated pages
    pagination = 100
  end
  extension Awestruct::Extensions::Paginator.new( :posts, 'index', :per_page=>pagination, :per_page_init=>pagination )
  
  if not editor
    extension Awestruct::Extensions::Splitter.new( :posts,
                                                   'tags',
                                                   'templates/tag',
                                                   '/tag',
                                                   :per_page=>10, :per_page_init=>10,
                                                   :output_home_file=>'index',
                                                   :sanitize=>true )
    extension Awestruct::Extensions::SplitCloud.new( :posts,
                                                   'tags',
                                                   '/tags/index.html',
                                                   :title=>'Tags')
    extension Awestruct::Extensions::Splitter.new( :posts,
                                                   'author',
                                                   'templates/author',
                                                   '/author',
                                                   :per_page=>10, :per_page_init=>10,
                                                   :output_home_file=>'index',
                                                   :sanitize=>true )
    extension Awestruct::Extensions::SplitCloud.new( :posts,
                                                   'author',
                                                   '/authors/index.html',
                                                   :title=>'Author')
  end

  # register extensions and transformers
  extension Awestruct::Extensions::WgetWrapper.new
  transformer Awestruct::Extensions::JsMinifier.new
  transformer Awestruct::Extensions::CssMinifier.new
  transformer Awestruct::Extensions::HtmlMinifier.new
  extension Awestruct::Extensions::FileMerger.new
  extension Awestruct::Extensions::Indexifier.new
  
  development = Engine.instance.site.profile == 'development'
  if not development and not editor
    extension Awestruct::Extensions::RedirectCreator.new "redirects", "hib-docs-reference-redirects", "hib-docs-v3-api-redirects"
  end
end

# vim: softtabstop=2 shiftwidth=2 expandtab
