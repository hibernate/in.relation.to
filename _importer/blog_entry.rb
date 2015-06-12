# encoding: UTF-8

# Class encapsulating the bits and pieces of a single post
class BlogEntry

  attr_accessor :title, :content, :author, :blogger_name, :tags, :assets, :slug, :date, :lace, :relative_url,:disqus_thread_id

  def to_erb
  	# quotes in title must be escaped, also backslash with double backslash
    escaped_title = @title.gsub(/\\/, '\&\&').gsub(/\"/, '\"')

  	# prepare comma separated list of tags
    tag_string = ""
    tags.each { |tag| tag_string = tag_string + tag + "," }
    tag_string = tag_string.gsub(/,$/, '')

    # prepare list of attachments
    if !assets.empty?
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

  def file_name
  	date_string = date.strftime( "%Y-%m-%d" )
  	return File.join( @blogger_name, "#{date_string}-#{slug}.html.erb" )
  end
end
