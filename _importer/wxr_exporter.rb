#!/usr/bin/env ruby
# encoding: UTF-8
require 'nokogiri'

# Class encapsulating the creation of a WXR comment exort file for Disqus
class WxrExporter
  $spam_keywords = ['sex',
                    'porn',
                    'penis',
                    'rolex',
                    'xxx',
                    'kitchen',
                    'handbag',
                    'replica',
                    'tinnitus',
                    'acne',
                    'ebook',
                    'loan']

  # array of suspected spam
  @spam

  # reference to the WXR template file
  @doc

  # the current item (blog post) to create comments for
  @current_item

  # counter for the number of created comments
  @number_of_comments

  # file to which to write the WXR XML
  @wxr_file_name

  def initialize(wxr_template_path, wxr_file_name)
    # read the template xml into memory
    @spam = Array.new
    @number_of_comments = 0
    @wxr_file_name = wxr_file_name


    abort "ERROR: #{wxr_template_path} is not a valid file" unless File.exist?(wxr_template_path)
    file = File.open(wxr_template_path)
    @doc = Nokogiri::XML(file)
    file.close
  end

  def create_item(title, url, body, id, creation_time)
    item = Nokogiri::XML::Node.new "item", @doc

    title_node = Nokogiri::XML::Node.new "title", @doc
    title_node.content = title
    item.add_child title_node

    link = Nokogiri::XML::Node.new "link", @doc
    link.content = url
    item.add_child link

    id_node = Nokogiri::XML::Node.new "dsq:thread_identifier", @doc
    id_node.content = id
    item.add_child id_node

    date = Nokogiri::XML::Node.new "wp:post_date_gmt", @doc
    date.content = creation_time.strftime("%Y-%m-%d %H:%M:%S")
    item.add_child date

    content = Nokogiri::XML::Node.new "content:encoded", @doc
    content.add_child @doc.create_cdata(body)
    item.add_child content

    @current_item = @doc.at_xpath("//channel").add_child item
  end

  def add_comment(id, author, email, url, creation_time, content)
    comment = Nokogiri::XML::Node.new "wp:comment", @doc

    comment_id = Nokogiri::XML::Node.new "wp:comment_id", @doc
    comment_id.content = id
    comment.add_child comment_id

    comment_author = Nokogiri::XML::Node.new "wp:comment_author", @doc
    comment_author.content = author
    comment.add_child comment_author

    comment_author_email = Nokogiri::XML::Node.new "wp:comment_author_email", @doc
    comment_author_email.content = email
    comment.add_child comment_author_email

    comment_author_url = Nokogiri::XML::Node.new "wp:comment_author_url", @doc
    comment_author_url.content = url
    comment.add_child comment_author_url

    comment_date = Nokogiri::XML::Node.new "wp:comment_date_gmt", @doc
    comment_date.content = creation_time.strftime("%Y-%m-%d %H:%M:%S")
    comment.add_child comment_date

    comment_content = Nokogiri::XML::Node.new "wp:comment_content", @doc
    comment_content.add_child @doc.create_cdata(content)
    comment.add_child comment_content

    # do some basic spam detection
    # if the author name is a link, it is most likley spam and an attempt to make a given
    # url as much visiblw as possible
    if author =~ /http:.*/
      @spam << comment.to_s
      return
    end

    spam_regexp = $spam_keywords.join('|')
    if content =~ /#{spam_regexp}/i
      @spam << comment.to_s
      return
    end

    # Disqus does not allow longer comments and they are most likely spam anyways
    if content.length > 25000
      @spam << comment.to_s
      return
    end

    # Not sure whether id there is a limit in theory, but Disqus does not even
    # allow that long emails
    if email.length > 75
      @spam << comment.to_s
      return
    end

    @current_item.add_child comment
    @number_of_comments += 1
  end

  def write_wxr
    File.open(@wxr_file_name, 'w') { |f| f.print(@doc.to_xml) }
    spam_file_name = @wxr_file_name + '-spam.xml'
    File.open(spam_file_name, 'w') { |f|
      f.print('<spam>\n')
      f.print(@spam.join('\n'))
      f.print('</spam>')
    }
    puts "\n\n"
    puts "------------------------------------------------------------------------"
    puts "Created #{@wxr_file_name} with #{@number_of_comments} comments for import into Disqus"
    puts "\n"
    puts "Skipped #{@spam.length} comments during import due to suspected SPAM."
    puts "Check #{spam_file_name}."
    puts "------------------------------------------------------------------------"
  end
end

# wxr_exporter = WxrExporter.new "./disqus.xml", "comments-wxr.xml"
# wxr_exporter.create_item("Hello world", "http://hello/world", "blah < >", "1", DateTime.now)
# wxr_exporter.add_comment("1", "Author 1", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")
# wxr_exporter.add_comment("2", "Author 2", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")

# wxr_exporter.create_item("Snafu
#       ", "http://hello/world", "blah < >", "1", DateTime.now)
# wxr_exporter.add_comment("3", "Author 3", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")

# wxr_exporter.write_wxr
