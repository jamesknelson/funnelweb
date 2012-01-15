require 'net/https'
require 'funnelweb/page'
require 'funnelweb/cookie_store'

module Funnelweb
  class Visit
    @queue = :crawler
    
    def self.perform(url, referer, options)
      # If the URL exists in the page database, check its last crawled time
      # If the time is less than options.fresh_until, don't crawl unless options[:force] is true
      # Find the crawler to use from the routes system
      # Merge options from craler
      # Download the page
    end
    
  end
end