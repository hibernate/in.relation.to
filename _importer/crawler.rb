#!/usr/bin/env ruby
# encoding: UTF-8

require "rubygems"
require "bundler/setup"

require_relative 'blog_entry'

require 'choice'
require 'anemone'
require 'pstore'
require 'pry-byebug'

Choice.options do
  header 'Application options:'

  separator 'Required:'

  option :url, :required => true do
    short '-u'
    long '--url=<file>'
    desc 'The base url'
  end

  option :pattern, :required => false do
    short '-p'
    long '--pattern=<regexp>'
    desc 'Regular expression to limit the discovered pages'
  end

  option :out, :required => true do
    short '-o'
    long '--out=<file>'
    desc 'The name of the output-file'
  end

  separator 'Common:'

  option :help do
    short '-h'
    long '--help'
    desc 'Show this message.'
  end
end

class Crawler

  def initialize(base_url, pattern, output_file)
    #puts ARGV
    @base_url = base_url
    @pattern = Regexp.new(pattern)
    @output_file = output_file
  end

  def crawl
    store = PStore.new(@output_file)
    reindex = Array.new
    saved_posts = 0
    Anemone.crawl(@base_url) do |anemone|
      anemone.on_pages_like(@pattern) do |page|

        if(page.code != 200)
          puts "INFO: #{page.url.to_s} scheduled for re-indexing, since it returned with HTTP error #{page.code}."
          reindex.push page.url.to_s
          next
        end

        if(too_many_active_users(page))
          reindex.push page.url.to_s
          next
        end

        store.transaction do
          store[page.url] = page.doc.to_s
          saved_posts += 1
          page_title = page.doc.css('title').text.gsub("\n","")
          puts "Persisted #{page.url.to_s} - #{page_title}"
        end

        #sleep(10)
      end

      anemone.after_crawl do
        reindex_failed_posts(reindex, store, saved_posts )
      end
    end
    puts "Total of #{saved_posts} posts persisted"
  end

  private

  def reindex_failed_posts(reindex, store, saved_posts)
    while !reindex.empty? do
        Anemone.crawl(reindex.first) do |a|
          a.focus_crawl do |page|
            page.links.slice(0)

            if(too_many_active_users(page))
              next
            end
            store.transaction do
              store[page.url] = page.doc.to_s
              saved_posts += 1
              puts "Persisted #{page.url.to_s}"
              reindex = reindex.drop(1)
            end
          end
        end
      end
    end
  end

  # Sometimes the site returns 200 OK, but the content of the page is not the blog entry, but the messge
  # "Too many active users". In this case the page must be re-indexed.
  def too_many_active_users(page)
    if(!page.doc.css.nil? && page.doc.css('title').text =~ /Too many active users/)
      puts "INFO: #{page.url.to_s} scheduled for re-indexing. The page reported: '#{page.doc.css('title').text}'"
      return true
    else
      return false
    end
  end

  crawler = Crawler.new( Choice.choices.url, Choice.choices.pattern, Choice.choices.out )
  crawler.crawl
