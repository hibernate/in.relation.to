#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "bundler/setup"

require_relative 'blog_entry'
require_relative 'wxr_exporter'

require 'choice'
require 'pstore'
require 'nokogiri'
require 'date'
require 'fileutils'
require 'net/http'
require 'uri'
require 'pathname'

require_relative 'normalize_tag'

Choice.options do
  header 'Application options:'

  separator 'Required:'

  option :pstore, :required => true do
    short '-s'
    long '--store=<file>'
    desc 'The PStore file containing the spidered HTML'
  end

  option :outdir, :required => true do
    short '-o'
    long '--out=<dir>'
    desc 'The name of the output directory'
  end

  separator 'Optional:'

  option :redirects_file, :required => false do
    short '-rf'
    long '--redirects-file=<file>'
    desc 'The name of file to which write HTTP redirect rules'
  end

  option :wxr, :required => false do
    short '-wxr'
    long '--wxr-export-file=<file>'
    desc 'The name of WXR XML file. If specified comments are exported, otherwise not'
  end

  separator 'Debugging:'

  option :errors, :required => false do
    short '-e'
    long '--log-errors'
    desc 'Whether failed imports should be logged with stacktrace'
  end

  option :lace, :required => false do
    short '-l'
    long '--lace=<lace-url>'
    desc 'Runs the importer only for the given lace url'
  end

  option :limit, :required => false do
    short '-n'
    long '--limit=<n>'
    desc 'Limit the imported posts (for debugging purposes)'
  end

  option :skip_images, :required => false do
    short '-ni'
    long '--no-images'
    desc 'Wether image processing should be skipped'
  end

  option :skip_assets, :required => false do
    short '-na'
    long '--no-assets'
    desc 'Wether asset processing should be skipped'
  end

  separator 'Common:'

  option :help do
    short '-h'
    long '--help'
    desc 'Show this message.'
  end
end

class Importer

  BASE_URL = "http://in.relation.to"
  CROSS_SITE_LINK_REG_EXP = '(\/Bloggers\/(\w+))'

  def initialize(import_file, output_dir, redirects_file, wxr_file_name, skip_image_processing, skip_asset_processing, log_errors, limit=-1, lace=nil)
    @import_file = import_file
    @output_dir = output_dir
    @skip_redirect_file_creation = redirects_file.nil? ? true : false
    @redirects_file = redirects_file

    @skip_wxr_export = wxr_file_name.nil? ? true : false
    unless @skip_wxr_export
      @wxr_exporter = WxrExporter.new "./disqus.xml", @output_dir + '/' + wxr_file_name
    end

    @skip_image_processing = skip_image_processing.nil? ? false : true
    @skip_asset_processing = skip_asset_processing.nil? ? false : true
    @log_errors = log_errors.nil? ? false : true
    @limit = limit
    @single_lace = lace

    # images and assets/attachments go into subdirectories
    @image_dir = @output_dir + '/../images/legacy'
    FileUtils.mkdir_p( @image_dir )
    @asset_dir = @output_dir + '/../assets'
    FileUtils.mkdir_p( @asset_dir )

    # Hash for the processed blog entries keyed against the wiki hash
    @blog_entries = Hash.new
  end

  def import_posts
    successful_imports = 0
    skipped_imports = 0
    failed_imports = 0
    failures = Hash.new
    posts = PStore.new(@import_file)

    # Process all blog posts stored in the PStore file
    posts.transaction(true) do
      posts.roots.each do |lace|
        if(!@single_lace.nil? && @single_lace != lace.to_s)
          next
        end

        # create a blog entry and parse its content
        blog_entry = BlogEntry.new
        blog_entry.lace = lace
        begin
          if(import_post(blog_entry, posts[lace]))
            @blog_entries[blog_entry.camel_case_slug] = blog_entry
            successful_imports += 1
          else
            skipped_imports += 1
          end
        rescue => e
          failed_imports += 1
          failures[lace] = e
        end
        if(@limit != -1 && successful_imports >= @limit )
          break
        end
      end
    end

    post_process_posts

    # Write the blog entries to disk
    @blog_entries.values.each do |blog_entry|
      write_file(blog_entry)
    end

    # Create the Disqus WXT import file if necessary
    unless @skip_wxr_export
      @wxr_exporter.write_wxr
    end

    # Create Apache redirects if necessary
    unless @skip_redirect_file_creation
      create_redirects
    end

    if(@log_errors == true)
      failures.each_pair do |k,v|
        puts "#{k} : #{v.message}"
        puts v.backtrace
        puts " "
        puts "--------------------------------------"
        puts " "
      end
    end

    puts "------------------------------------------------------------------------"
    puts "Successfull imports #{successful_imports}"
    puts "Skipped imports #{skipped_imports}"
    puts "Failed imports #{failed_imports}"
    puts "------------------------------------------------------------------------"
  end

  private

  def import_post(blog_entry, content)
    doc = Nokogiri::HTML(content)

    if(doc.css('title').text =~ /Too many active users/)
      puts "WARN: #{blog_entry.lace} needs to be spidered again. The page reported: '#{doc.css('title').text}'"
      return false
    end

    # title and wiki title
    title_link = doc.css('h1.documentTitle > a').first

    # some people mananged to write blog posts where the title is only in the breadcrumb - go figure!?
    if(title_link.nil?)
      title_link = doc.css('div.breadcrumb a[class = "itemText"]')
    end

    if(title_link.nil? || title_link.text.nil?)
      puts "WARN: #{blog_entry.lace} does not seem to have title and/or title link"
    end

    blog_entry.title = title_link.text
    printf "Importing   %-42s - %s\n", blog_entry.lace, blog_entry.title
    blog_entry.slug = title_link.attr('href').to_s.sub('/Bloggers/', '')

    # author and blogger name
    author_link = doc.css('div.documentCreatorHistory > div > a').first
    if(author_link.nil?)
      # in some cases the author name is not linked. Parse the text instead
      author = doc.css('div.documentCreatorHistory > div').first.content.strip.gsub(/.*\(/, '').gsub(/\).*/, '')
      blog_entry.author = author
      blog_entry.blogger_name = author.split(" ").first
    else
      blog_entry.author = author_link.text
      blog_entry.blogger_name = author_link.attribute('href').to_s.sub('/Bloggers/', '')

      # Hack for this specific post where a diff is linked instead of the author
      if blog_entry.lace.to_s == "http://in.relation.to/10440.lace"
        blog_entry.author = "Aleš Justin"
        blog_entry.blogger_name = "Ales"
      end
    end

    # creation date
    published_string = doc.css('div.documentCreatorHistory > div').first.text.strip.gsub(/Created:/, '').gsub(/\(.*/, '')
    blog_entry.date = DateTime.parse( published_string )

    # tags
    tags = doc.css('div.documentTags  a').map {|link| link.text.to_s}
    blog_entry.original_tags = tags
    blog_entry.tags = normalize_tags(blog_entry.slug, tags)

    # misc
    blog_entry.relative_url = "/#{blog_entry.date.strftime('%Y/%m/%d')}/#{blog_entry.slug}"
    blog_entry.disqus_thread_id = "http://in.relation.to" + blog_entry.relative_url

    # prepare the main content
    blog_entry.content_node = prepare_content_body(doc, blog_entry)

    unless @skip_wxr_export
      @wxr_exporter.create_item(blog_entry.title,
                                blog_entry.disqus_thread_id,
                                blog_entry.content_node.to_s,
                                blog_entry.date.strftime( "%d-%m-%Y" ) + '-' + blog_entry.slug,
                                blog_entry.date)
      export_comments(doc)
    end

    return true
  end

  def create_redirects
    authors = Hash.new
    tags = Set.new

    redirects = File.open( @redirects_file, 'w')
    redirects.write "# Generated by #{File.basename($PROGRAM_NAME)}\n\n"

    # Blog posts
    redirects.write "### Blog posts\n\n"
    @blog_entries.values.sort_by{|blog_entry| "#{blog_entry.date.strftime('%Y/%m/%d')}/#{blog_entry.slug}"}.reverse.each do |blog_entry|
      blog_entry.original_tags.each do |tag|
        tags << tag.strip
      end

      redirects.write "RewriteRule ^/Bloggers/#{blog_entry.camel_case_slug}$ /#{blog_entry.date.strftime('%Y/%m/%d')}/#{blog_entry.slug}/ [R=301,L,E=nocache:1]\n"
      redirects.write "RewriteRule ^/#{blog_entry.lace.path[1..-1]}$ /#{blog_entry.date.strftime('%Y/%m/%d')}/#{blog_entry.slug}/ [R=301,L,E=nocache:1]\n\n"
    end

    # Tags
    redirects.write "### Tags\n\n"

    tags.sort{|tag1, tag2| res = tag1.casecmp(tag2); res != 0 ? res : tag2 <=> tag1}.each do |tag|
      new_tag = normalize_tag(tag)
      if (!new_tag.nil?)
        redirects.write "RewriteRule ^/tag/" + tag.gsub(' ', "\\\\+") + "$ /#{new_tag.downcase.gsub(' ', '-')}/ [R=301,L,E=nocache:1]\n"
      end
    end
    redirects.write "RewriteRule ^/tag/.* / [R=301,L,E=nocache:1]\n"

    redirects.close
  end

  # Extracts and cleans up the main content of the blog post
  def prepare_content_body(doc, blog_entry)
    #puts doc
    content_node = doc.search('#documentDisplay')

    # remove the empty first wikiPara
    if(content_node.css('p.wikiPara')[0].text.strip!.empty?)
      content_node.css('p.wikiPara')[0].unlink
    end

    # remove h1 title since title will be rendered on the new site via the meta data
    content_node.css('div#j_id490').unlink

    # adjust anchor links (used in blog headings)
    content_node.css('a').each do |link_node|
      if link_node['href'] =~ /^\/Bloggers\/.*(#.*)$/
        updated_href = blog_entry.relative_url + link_node['href'].match(/^\/Bloggers\/.*(#.*)$/).captures[0]
        link_node['href'] = updated_href
      end
    end

    unless @skip_image_processing
      import_images(content_node)
    end

    unless @skip_asset_processing
      blog_entry.assets = import_assets(doc, blog_entry.slug, content_node)
    end

    return content_node
  end

  # Process all comments of a given blog. They all within a table and one comment is within a column
  # of the class 'contentColumn'. The actual content is in a 'commentText' div, whereas the
  # author information is in two diffs which are children of a 'commentAuthorInfo' td node.
  def export_comments(doc)
    doc.css('td.commentColumn').each do |comment|
      begin
        comment_id = comment.css('a[id^="comment"]')[0]['id'].gsub!(/comment/, '')
        comment_node = comment.css('div.commentText')
        comment_content = nil
        if  comment_node.attribute("class").to_s =~ /plaintext/
          comment_content = comment_node[0].content
        else
          comment_content = comment_node.inner_html.strip
        end

        comment_date = parse_comment_date comment.css('td.commentAuthorInfo div')[0]
        author, email, url = parse_author_info comment.css('td.commentAuthorInfo div')[1]

        # puts "===> author  : " << author
        # puts "     email   : " << email
        # puts "     url     : " << url
        # puts "     date    : " << comment_date.to_s
        # puts "     content : " << comment_content
        # puts "\n\n"

        @wxr_exporter.add_comment(comment_id, author, email, url, comment_date, comment_content)
      rescue => e
        puts "-------------------------------------------"
        puts "WARN: Skipping import of comment: \n"
        puts comment
        puts e
        puts e.backtrace
        puts "-------------------------------------------"
      end
    end
  end

  def parse_comment_date(comment_date_node)
    date_as_string = comment_date_node.css('span.commentDate')[0].content
    # eg '19. Dec 2014, 01:31 CET'
    DateTime.parse(date_as_string)
  end

  # The parsing of the comments author is a bit tricky. Partly because the comments form on
  # in.relation.to is quite liberal what you can enter and partly because the various elements are
  # not nicely separated in their own components. Instead author name, email and urk needs to be
  # extraced from a single string
  #
  # An example could be '<a href="http://www.acme.com">Acme</a> | <a href="mailto:admin(AT)acme.com">Acme Admin</a>'
  # hrefs are optional and if there is only a name the '|' is missing
  def parse_author_info(author_node)
    author_info = author_node.inner_html.to_s

    # if the author provided a website as well the string is <website> | <email>
    if author_info =~ /\|/
      url = ''
      author_name, email = author_info.split('|', 2)
      if author_name =~ /href/
        url, author_name = author_name.match(/^.*href="(.*)">(.*)<\/a>.*$/).captures
      end

      email = email.match(/^.*href="mailto:(.*)">.*$/).captures[0]
      email.sub!('(AT)', "@")
      email.strip!
      return [author_name, email, url]
      # there is no email, but a website
    else
      url = ''
      author_name = author_info
      if author_name =~ /href/
        url, author_name = author_name.match(/^.*href="(.*)">(.*)<\/a>.*$/).captures
      end
      author_name.strip!
      url.strip!
      return [author_name, '', url]
    end
  end

  def import_images(content_node)
    content_node.css('img').each do |image|
      # match images either as absolute in.relation.to url or site relative
      if (image['src'] =~ /http:\/\/in.relation.to\/service\/File/ || image['src'] =~ /^\/service\/File/)
        # get the image and type
        image_path = image['src'].gsub(/\?thumbnail=true/, '')
        image_name = image_path.split('/').last
        if(Dir.glob(File.join(@image_dir, "#{image_name}.*")).size > 0)
          file_name = Dir.glob(File.join(@image_dir, "#{image_name}.*"))[0]
          image_name << File.extname(file_name)
        else
          image_data, type = download_resource(image_path)

          # append type
          image_name << '.' << type

          # write the image
          write_resource(image_data, File.join( @image_dir, image_name ))
        end

        # adjust the image target
        image['src'] = "/images/legacy/" + image_name
      end
    end
  end

  def import_assets(doc, slug, content_node)
    # attachements are in a table at the bottom of the post. Let's process the table first and then adjust the actual post content
    prefix = slug + "_"
    attachments = Hash.new
    attachment_count = 1
    doc.css('div.attachmentDisplay tr').each do |attachment_row|
      attachment_row.css('a').map do |a|
        if(a['href'] =~ /\/service\/File/)
          # get the asset
          url = BASE_URL + a['href']

          # try to determine its original name
          regexp = /\((.*), [0-9]/
          m = regexp.match(a.text)
          m.captures.each do |original_file_name|
            assetPath = File.join( @asset_dir, original_file_name )
            if(!File.exists?(assetPath))
              # download and save
              asset = download_resource(url)[0]
              write_resource(asset, assetPath )
            end

            anchor = prefix + "attachment" + attachment_count.to_s
            attachments[anchor] = original_file_name
            attachment_count += 1
          end
        end
      end
    end
    # last but ot least we have to adjust the link in the actual post (it is just an anchor to the attachment table)
    attachments.each_pair do |k,v|
      content_node.css('a').map do |a|
        # The new anchor looks like Hibernate2MillionDownloads5Years25Books_attachment1
        # the original anchor looks like attachment1
        originalAnchor = k.sub( prefix, "" )
        if (a['href'] =~ /\##{originalAnchor}/)
          a['href'] = "\##{k}"
        end
      end
    end
  end

  def download_resource(resource_url)

    if( resource_url !~ /http:\/\/in.relation.to/ )
      resource_url = 'http://in.relation.to' + resource_url
    end

    printf "Downloading %-42s\n", resource_url
    uri = URI.parse( resource_url )

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)

    resource = response.body
    type = response["content-type"].split('/', 2).last
    return [resource, type]
  end

  def write_resource(resource, file_name)
    #puts "Writing #{file_name}"
    File.open( file_name, 'wb' ) do |f|
      f.write resource
    end
  end

  def write_file(blog_entry)
    out = File.join( @output_dir, blog_entry.file_name )
    # make sure the directory exists
    FileUtils.mkdir_p( File.dirname( out ) )
    File.open( out, 'w' ) do |f|
      f.puts blog_entry.to_erb
    end
  end

  # Do some post processing of the posts after all have been collected in the blog entries hash
  def post_process_posts
    @blog_entries.each do |wiki_slug, blog_entry|
      update_cross_referencing_links blog_entry
    end
  end

  # Some posts cross reference other posts. Let's update the links pointing to them
  def update_cross_referencing_links(blog_entry)
    blog_entry.content_node.css('a').each do |link_node|
      if link_node['href'] =~ /#{CROSS_SITE_LINK_REG_EXP }/
        cross_site_slug = link_node['href'].match(/#{CROSS_SITE_LINK_REG_EXP }/).captures[1]
        if @blog_entries.has_key? cross_site_slug
          link_node['href'] = link_node['href'].sub(/#{CROSS_SITE_LINK_REG_EXP }/, "#{@blog_entries[cross_site_slug].relative_url}")
        end
      end
    end
  end
end

limit = -1
if(Choice.choices[:limit])
  limit = Choice.choices[:limit].to_i
end

lace = nil
if(Choice.choices[:lace])
  lace = Choice.choices[:lace]
end
importer = Importer.new(Choice.choices.pstore,
                        Choice.choices.outdir,
                        Choice.choices.redirects_file,
                        Choice.choices.wxr,
                        Choice.choices.skip_images,
                        Choice.choices.skip_assets,
                        Choice.choices.errors,
                        limit,
                        lace
                        )
importer.import_posts
