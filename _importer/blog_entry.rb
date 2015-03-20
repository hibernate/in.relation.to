# encoding: UTF-8

# Class encapsulating the bits and pieces of a single post
class BlogEntry

  attr_accessor :title, :content, :author, :blogger_name, :tags, :slug, :date, :lace

  def to_erb
  	# quotes in title must be escaped, also backslash with double backslash
    escaped_title = @title.gsub(/\\/, '\&\&').gsub(/\"/, '\"')

  	# prepare comma separated list of tags
    tag_string = ""
    tags.each { |tag| tag_string = tag_string + tag + "," }
    tag_string = tag_string.gsub(/,$/, '')

    erb = "---\n" <<
    "title: \"#{escaped_title}\"\n" <<
    "author: \"#{@author}\"\n" <<
    "creation_date: \"#{@date.strftime( "%d-%m-%Y" )}\"\n" <<
    "blogger_name: \"#{@blogger_name}\"\n" <<
    "layout: blog-post\n" <<
    "tags: [#{tag_string}]\n" <<
    "slug: #{slug}\n" <<
    "lace: #{@lace}\n" <<
    "---\n" <<
    "#{content}\n" <<
    "<div id=\"disqus_thread\"></div>" <<
    "<script type=\"text/javascript\">\n" <<
    "    var disqus_shortname = 'otnoitalerni';\n" <<
    "    var disqus_identifier = '#{@slug}';\n" <<
    "    var disqus_title = '#{@title}';\n" <<
    "    var disqus_url = '#{@lace}';\n" <<
    "\n" <<
    "    (function() {\n" <<
    "        var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;\n" <<
    "        dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';\n" <<
    "        (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);\n" <<
    "    })();\n" <<
    "</script>\n" <<
    "<noscript>Please enable JavaScript to view the <a href=\"https://disqus.com/?ref_noscript\" rel=\"nofollow\">comments powered by Disqus.</a></noscript>"

  end

  def file_name
  	date_string = date.strftime( "%Y-%m-%d" )
  	return File.join( @blogger_name, "#{date_string}-#{slug}.html.erb" )
  end
end
