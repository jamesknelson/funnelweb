require 'active_support/core_ext/class/attribute_accessors'

require 'funnelweb/routing'
require 'funnelweb/web_client'

module Funnelweb
  class Crawler
    @queue = :crawler
    #
    # This is called by Resque workers to start the proces of a visit 
    #
    def self.perform(url, depth, options = {})
      WebClient.get(url, referer, options) do |crawler|  
        
        if depth > crawler.class.config[:depth_limit]
          # Raise an exception, as this is probably an error with the crawler, not the site
          raise StandardError.new("Depth is #{depth}, which is higher than allowed depth #{options[:depth_limit]}")
        end     
        
        crawler.process
      end
    end
    
    
    cattr_accessor :config
    @@config = {}

    # 
    # Configure the settings for a crawler
    # 
    def self.configure(options)
      config.merge!(options)
    end
    
    def self.map(options)
      Funnelweb::Routing.map(options.merge(:to => self))
    end


    
    def initialize(visit)
      @visit = visit
    end
    
    def match(&block)
      
    end
    def filter(&block)
      
    end
    def follow(&block)
      
    end
    
    #
    # Schedule a re-crawl this at *time*. If a re-crawl is already scheduled, change it.
    # +nil+ cancels any existing recrawl.
    #
    def recrawl(time)
      
    end
    
    #
    # Adds all links which match *selector* to the crawl queue immediately
    #
    def crawl(selector)
      
    end
    
    #
    # URI object for the URL for the page
    #
    def url
      @url ||= URI(visit.url)
    end
    
    #
    # Nokogiri document for the HTML body
    #
    def doc
      @doc ||= Nokogiri::HTML(visit.body) if visit.body && visit.html? rescue nil
    end
    
    #
    # Delete the Nokogiri document to conserve memory
    #
    def discard_doc!
      @doc = nil
    end
    
    def visit
      @visit
    end
    
    #
    # Converts relative URL *link* into an absolute URL based on the
    # location of the page
    #
    def to_absolute(link)
      return nil if link.nil?

      # remove anchor
      link = URI.encode(URI.decode(link.to_s.gsub(/#[a-zA-Z0-9_-]*$/,'')))

      relative = URI(link)
      absolute = url.merge(relative)

      absolute.path = '/' if absolute.path.empty?

      return absolute
    end
    
    #
    # Returns +true+ if *uri* is in the same domain as the page, returns
    # +false+ otherwise
    #
    def in_domain?(uri)
      uri.host == url.host
    end
    
    def process
      raise NotImplemented
    end
    
  end
end