#!/usr/bin/env ruby
# encoding: UTF-8
require 'nokogiri'

# Class encapsulating the creation of a WXR comment exort file for Disqus
class WxrExporter
	# reference to the WXR template file
	@doc

	# reference to the original item node (used as template)
	@master_item

    # reference to the oringal comment node (used as template)
	@master_comment

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

        # get the item node
		@master_item = @doc.at_xpath("//item")
		@master_item.xpath('//comment()').remove

        # get the comment node
		@master_comment = @master_item.at_xpath("wp:comment")
		@master_comment.at_xpath("//dsq:remote").remove
		@master_comment.unlink
	end

	def create_item(title, url, body, id, creation_time)
		item = @master_item.dup
		item.at_xpath("//title").content = title
		item.at_xpath("//link").content = url
		item.at_xpath("//content:encoded").children.find{|node|
			if node.cdata?
				node.content = body
			end
		}
		item.at_xpath("//dsq:thread_identifier").content = id
		item.at_xpath("//wp:post_date_gmt").content = creation_time.strftime("%Y-%m-%d %H:%M:%S")
		@master_item.before item
		@current_item = item
	end

	def add_comment(id, author, email, url, ip, creation_time, content)
		if @current_item.nil?
			abort "ERROR: There is no item for adding a comment"
		end

		comment = @master_comment.dup

		comment.at_xpath("wp:comment_id").content = id
		comment.at_xpath("wp:comment_author").content = author
		comment.at_xpath("wp:comment_author_email").content = email
		comment.at_xpath("wp:comment_author_url").content = url
		comment.at_xpath("wp:comment_author_IP").content = ip
		comment.at_xpath("wp:comment_date_gmt").content = creation_time.strftime("%Y-%m-%d %H:%M:%S")
		comment.at_xpath("wp:comment_content").children.find{|node|
			if node.cdata?
				node.content = content
			end
		}

        #append the comment to the current item
		@current_item << comment
	end

	def write_wxr
		# unlink the original master node. It was just used as a template
		@master_item.unlink
		File.open(@output_path, 'w') { |f| f.print(@doc.to_xml) }
	end
end

# wxr_exporter = WxrExporter.new "./disqus.xml", "comments-wxr.xml"
# wxr_exporter.create_item("Hello world", "http://hello/world", "blah < >", "1", DateTime.now)
# wxr_exporter.add_comment("1", "Author 1", "foo@mailinator.com", "http://foobar.com", "127.0.0.1", DateTime.now, "Test comment")
# wxr_exporter.add_comment("2", "Author 2", "foo@mailinator.com", "http://foobar.com", "127.0.0.1", DateTime.now, "Test comment")

# wxr_exporter.create_item("Snafu
# 	", "http://hello/world", "blah < >", "1", DateTime.now)
# wxr_exporter.add_comment("3", "Author 3", "foo@mailinator.com", "http://foobar.com", "127.0.0.1", DateTime.now, "Test comment")

# wxr_exporter.write_wxr
