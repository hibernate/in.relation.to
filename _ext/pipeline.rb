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
require 'paginator'
require 'posts'
require 'date'

require 'legacy_post_code_highlighter'

require 'i18n'
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

  ignore_older_than=nil
  if !Engine.instance.site.ignore_older_than_days.nil? && Engine.instance.site.ignore_older_than_days.to_i > 0
    ignore_older_than = Time.now - Engine.instance.site.ignore_older_than_days.to_i * 24 * 60 * 60
  end

  extension Awestruct::Extensions::Posts.new( '', :posts, nil, nil, ignore_older_than )
  extension Awestruct::Extensions::SplitFilterer.new( :posts,
                                                     'tags',
                                                     :sanitize=>true,
                                                     :blacklist=>['author', 'authors', 'tags', 'tag',
                                                      'page', 'javascripts', 'images', 'readme', 'templates']
                                                    )

  if Engine.instance.site.profile != 'editor'
    extension Awestruct::Extensions::Splitter.new( :posts,
                                                   'tags',
                                                   'templates/tag',
                                                   '',
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
                                                   '',
                                                   :per_page=>10, :per_page_init=>10,
                                                   :output_home_file=>'index',
                                                   :sanitize=>true )
    extension Awestruct::Extensions::Atomizer.new( :posts,
                                                   '/blog.atom',
                                                   :template=>File.join(File.dirname(__FILE__), 'template.atom.haml'),
                                                   :feed_title=>'In Relation To Blog')
  end

  extension Awestruct::Extensions::Paginator.new( :posts, 'index', :per_page=>10, :per_page_init=>10 )


  # register extensions and transformers
  transformer Awestruct::Extensions::JsMinifier.new
  transformer Awestruct::Extensions::CssMinifier.new
  transformer Awestruct::Extensions::HtmlMinifier.new
  transformer InRelationTo::Extensions::LegacyPostCodeHighlightingTransformer.new

  extension   Awestruct::Extensions::WgetWrapper.new
  extension   Awestruct::Extensions::FileMerger.new
  extension   Awestruct::Extensions::Indexifier.new

end

# vim: softtabstop=2 shiftwidth=2 expandtab
