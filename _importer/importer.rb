#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "bundler/setup"

require_relative 'blog_entry'

require 'choice'
require 'pstore'
require 'nokogiri'
require 'date'
require 'fileutils'
require 'net/http'
require 'uri'

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

  option :errors, :required => false do
    short '-e'
    long '--log-errors'
    desc 'Whether failed imports should be logged with stacktrace'
  end

  option :limit, :required => false do
    short '-l'
    long '--limit=<n>'
    desc 'Limit the imported posts (for debugging purposes)'
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

  def initialize(import_file, output_dir, skip_image_procesing, skip_asset_procesing, log_errors, limit=-1)
    @skip_image_procesing = skip_image_procesing.nil? ? false : true
    @skip_asset_procesing = skip_asset_procesing.nil? ? false : true
    @log_errors = log_errors.nil? ? false : true
    @limit = limit

    @import_file = import_file
    @output_dir = output_dir

    # images and assets/attachments go into subdirectories
    @image_dir = @output_dir + '/images'
    FileUtils.mkdir_p( @image_dir )
    @asset_dir = @output_dir + '/assets'
    FileUtils.mkdir_p( @asset_dir )
  end

  def import_posts
    successful_imports = 0
    skipped_imports = 0
    failed_imports = 0
    failures = Hash.new
    posts = PStore.new(@import_file)
    posts.transaction(true) do
      posts.roots.each do |lace|
        # create a blog entry and parse its content
        blog_entry = BlogEntry.new
        blog_entry.lace = lace
        begin
          if(import_post(blog_entry, posts[lace]))
            write_file(blog_entry)
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

    if(@log_errors == true)
      failures.each_pair do |k,v|
        puts "#{k} : #{v.message}"
        puts v.backtrace
        puts " "
        puts "--------------------------------------"
        puts " "
      end
    end

    puts "-------------------------------------------"
    puts "Successfull imports #{successful_imports}"
    puts "Skipped imports #{skipped_imports}"
    puts "Failed imports #{failed_imports}"
    puts "-------------------------------------------
    "
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
    blog_entry.slug = title_link.attr('href').to_s.sub('/Bloggers/', '')

    # remove the h1 title (title will be rendered from the meta information)
    blog_entry.content = prepare_content_body(doc)

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
    end

    # creation date
    published_string = doc.css('div.documentCreatorHistory > div').first.text.strip.gsub(/Created:/, '').gsub(/\(.*/, '')
    blog_entry.date = DateTime.parse( published_string )

    # tags
    blog_entry.tags = doc.css('div.documentTags  a').map {|link| link.text.to_s}

    if(!@skip_image_procesing)
      import_images(doc)
    end

    if(!@skip_asset_procesing)
      import_assets(doc)
    end

    return true
  end

  # Extracts and cleans up the main content of the blog post
  def prepare_content_body(doc)
    #puts doc

    content_node = doc.search('#documentDisplay')

    # remove the empty first wikiPara
    if(content_node.css('p.wikiPara')[0].text.strip!.empty?)
      content_node.css('p.wikiPara')[0].unlink
    end

    # remove h1 title since title will be rendered on the new site via the meta data
    content_node.css('div#j_id490').unlink

    # extract comments node
#    TODO - plugin disqus
#    comments = doc.search('#comments')

#    clean_comments = Nokogiri::XML::Node.new "div", doc
#    comments.css('table.commentHeader').each do |comment|
#      clean_comments << comment
#    end

    content = content_node.to_s
    return content
  end

  def import_images(doc)
    content = doc.search('#documentDisplay')
    content.css('img').map do |image|
      if (image['src'] =~ /http:\/\/in.relation.to\/service\/File/)
        # get the image
        image_data = download_resource(image['src'])

        # just keep the image name (a number in our case)
        image_name = image['src'].split('/').last.gsub(/\?thumbnail=true/, '')

        # write the image
        write_resource(image_data, File.join( @image_dir, image_name ))

        # adjust the image target
        # TODO - verify this is the correct path. Where and how do images go in awestruct
        image['src'] = "<%= site.base_url %>/images/" + image_name
      end
    end
  end

  def import_assets(doc)
    # attachements are in a table at the bottom of the post. Let's process the table first and then adjust the actual post content
    attachments = Hash.new
    attachment_count = 1
    doc.css('div.attachmentDisplay tr').map do |attachment_row|
      attachment_row.css('a').map do |a|
        if(a['href'] =~ /\/service\/File/)
          # get the asset
          url = BASE_URL + a['href']

          # try to determine its original name
          regexp = /\((.*), [0-9]/
          m = regexp.match(a.text)
          m.captures.each do |original_file_name|
            # download and save
            asset = download_resource(url)
            write_resource(asset, File.join( @asset_dir, original_file_name ))
            attachments["attachment" + attachment_count.to_s] = original_file_name
            attachment_count += 1
          end
        end
      end
    end
    # last but ot least we have to adjust the link in the actual post (it is just an anchor to the attachment table)
    attachments.each_pair do |k,v|
      doc.css('div[id = "documentDisplayContainer"] a').map do |a|
        if(a['href'] =~ /\##{k}/)
          a['href'] = "<%= site.base_url %>/assets/" + v
          a.content = a.content.gsub(/\[.*\]/, '')
        end
      end
    end
  end

  def download_resource(resource_url)
    #puts "Downloading #{resource_url}"
    url = URI.parse( resource_url )
    resource = Net::HTTP.start(url.host, url.port) {|http|
      http.get(url.path)
    }
    return resource
  end

  def write_resource(resource, file_name)
    #puts "Writing #{file_name}"
    File.open( file_name, 'wb' ) do |f|
      f.write resource.body
    end
  end

  def write_file(blog_entry)
    out = File.join( @output_dir, blog_entry.file_name )
    # makre sure the directory exists
    FileUtils.mkdir_p( File.dirname( out ) )
    File.open( out, 'w' ) do |f|
      f.puts blog_entry.to_erb
    end
  end
end

limit = -1
if(Choice.choices[:limit])
  limit = Choice.choices[:limit].to_i
end
importer = Importer.new(Choice.choices.pstore, Choice.choices.outdir, Choice.choices.skip_images, Choice.choices.skip_assets, Choice.choices.errors, limit)
importer.import_posts
