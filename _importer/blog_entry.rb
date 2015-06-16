# encoding: UTF-8
require 'i18n'

I18n.enforce_available_locales = false

# Class encapsulating the bits and pieces of a single post
class BlogEntry

  attr_accessor :title, :content, :author, :assets, :blogger_name, :original_tags, :tags, :slug, :date, :lace, :relative_url,:disqus_thread_id

  def slug=(camel_case_slug)
    @slug = pretty_print_slug(camel_case_slug)
#    open('slugs.txt', 'a') { |f|
#      f.puts "#{@slug}\n"
#    }
  end

  def blogger_name=(name)
    @blogger_name = I18n.transliterate(name)
  end

  def to_erb
  	# quotes in title must be escaped, also backslash with double backslash
    escaped_title = @title.gsub(/\\/, '\&\&').gsub(/\"/, '\"')

  	# prepare comma separated list of tags
    tag_string = tags_to_string(tags);
    original_tag_string = tags_to_string(original_tags);

    # prepare list of attachments
    if !assets.nil? && !assets.empty?
      assets_content = '<div class="attachments">' <<
                     "\n" <<
                     '<h4>Attachments</h4>' <<
                     "\n" <<
                     '<ol class="wikiOrderedList">'
      assets.each { |anchor, filename| assets_content += '<li class="wikiOrderedListItem"><a name="' + anchor + '" href="/assets/' + filename + '">' + filename + '</a></li>' + "\n" }
      assets_content += "</ol>\n</div>\n\n"
    end

    # Prepare ERB content
    erb = "---\n" <<
    "title: \"#{escaped_title}\"\n" <<
    "author: \"#{@author}\"\n" <<
    "blogger_name: \"#{@blogger_name}\"\n" <<
    "creation_date: \"#{@date.strftime( "%d-%m-%Y" )}\"\n" <<
    "original_tags: [#{original_tag_string}]\n" <<
    "tags: [#{tag_string}]\n" <<
    "\n" <<
    "relative_url: #{@relative_url}\n" <<
    "slug: #{@slug}\n" <<
    "lace: #{@lace}\n" <<
    "\n" <<
    "layout: blog-post\n" <<
    "\n" <<
    "disqus_thread_id: #{@disqus_thread_id}\n" <<
    "---\n" <<
    "#{content}\n" <<
    "\n" <<
    "#{assets_content}"
  end

  def tags_to_string(tags)
    tag_string = ""
    tags.each { |tag| tag_string = tag_string + tag + "," }
    tag_string = tag_string.gsub(/,$/, '')
    return tag_string
  end

  def file_name
  	date_string = date.strftime( "%Y-%m-%d" )
  	return File.join( @blogger_name, "#{date_string}-#{slug}.html.erb" )
  end

  private

  def pretty_print_slug(camel_case_slug)
    camel_case_slug.gsub(/JBoss/,'jboss').    # handling some special cases
    gsub(/JBug/,'jbug').
    gsub(/JUDCon/,'judcon').
    gsub(/(\D+)([0-9]+)/,'\1-\2').            # dash before a sequence of numbers
    gsub(/([0-9]+)(\D+)/,'\1-\2').            # dash after a sequence of numbers
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1-\2').     # dash before a new uppercase word
    gsub(/([a-z])([A-Z])/,'\1-\2').           # dash after a word
    downcase
  end
end
