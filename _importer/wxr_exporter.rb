#!/usr/bin/env ruby
# encoding: UTF-8
require 'nokogiri'

# Class encapsulating the creation of a WXR comment exort file for Disqus
class WxrExporter
	# reference to the WXR template file
	@doc

	# the current item (blog post) to create comments for
	@current_item

	# path to which to write the WXR XML file
	@output_path

	def initialize(wxr_template_path, output_path)
		# read the template xml into memory
		@output_path = output_path
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

        id = Nokogiri::XML::Node.new "dsq:thread_identifier", @doc
        id.content = creation_time.strftime('%d-%m-%Y') + '-' + id
        item.add_child id

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

		@current_item.add_child comment
	end

	def write_wxr
		# unlink the original master node. It was just used as a template
		File.open(@output_path, 'w') { |f| f.print(@doc.to_xml) }
	end
end

wxr_exporter = WxrExporter.new "./disqus.xml", "comments-wxr.xml"
wxr_exporter.create_item("Hello world", "http://hello/world", "blah < >", "1", DateTime.now)
wxr_exporter.add_comment("1", "Author 1", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")
wxr_exporter.add_comment("2", "Author 2", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")

wxr_exporter.create_item("Snafu
	", "http://hello/world", "blah < >", "1", DateTime.now)
wxr_exporter.add_comment("3", "Author 3", "foo@mailinator.com", "http://foobar.com", DateTime.now, "Test comment")

wxr_exporter.write_wxr
