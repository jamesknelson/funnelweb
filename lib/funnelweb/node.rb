module Funnelweb
  class Node
    def initialize(crawler, page)
      @page = page
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
      @url = URI(@page.url)
    end
    
    #
    # Nokogiri document for the HTML body
    #
    def doc
      @doc ||= Nokogiri::HTML(@page.body) if @page.body && @page.html? rescue nil
    end
    
    #
    # Delete the Nokogiri document to conserve memory
    #
    def discard_doc!
      @doc = nil
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
      absolute = @url.merge(relative)

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
  end
end