require 'active_support/core_ext/class/attribute_accessors'
require 'nokogiri'
require 'resque'

require 'funnelweb/routing'
require 'funnelweb/web_client'


module Funnelweb
  
  #
  # Enqueue a visit for the "entry" url of the given crawler
  #
  def self.crawl(name, options = {})
    klass = options[:class] ||
      begin
        class_name = "#{name.to_s.classify}Crawler"
        Kernel.const_get(class_name)
      rescue
        raise ArgumentError.new("The class #{class_name} does not exist or was not loaded.")
      end
    
    if klass.config[:entry].nil?
      raise ArgumentError.new("The crawler you specified does not have an entry point specified.") 
    end
    
    Crawler.enqueue(klass.config[:entry], :force => true)
  end
  
  class Crawler
    @queue = :crawler
    
    #
    # This is called by Resque workers to start the proces of a visit 
    #
    def self.enqueue(url, options)
      Funnelweb.logger.debug "Enqueueing #{url.to_s}"
      Resque.enqueue(Crawler, url.to_s)
    end
    
    def self.perform(url, options = {})
      Funnelweb.logger.info "\n- Unqueuing #{url}".light_cyan
      
      referer = options[:referer]
      depth = options[:depth] || 1

      crawler_class = Routing.crawler(url)      
      options = Funnelweb.config.merge(crawler_class.config.merge(options))
            
      Funnelweb.logger.info "  Processing with #{crawler_class.to_s} @ depth #{depth}".cyan

      if depth > options[:depth_limit]
        # Raise an exception, as this is probably an error with the crawler, not the site
        raise StandardError.new("Depth is #{depth}, which is higher than allowed depth #{options[:depth_limit]}")
      end
    
      visits = WebClient.get(url, depth, referer, options)
      unless visits.empty?
        crawler = crawler_class.new(visits.last, depth)
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


    
    def initialize(visit, depth)
      @visit = visit
      @depth = depth
    end
    
    #
    # Each time a page is processed, only the first match statement which matches the
    # given conditions is execute
    #
    def match(conditions, &block)
      if !@matched
      
        host = conditions[:host]
        path = conditions[:path]
        query = conditions[:query]
        selectors = Array(conditions[:selectors])
      
        unless path.is_a? Regexp or path.nil?
          raise ArgumentError, "path must start with /, or be a Regex" unless path[0] == ?/
          path = path.chomp('/') unless path.nil?
          path = Regexp.new("^#{Regexp.quote(path).gsub('/', '/+')}\/?$", nil, 'n')
        end
      
        unless query.is_a? Regexp or query.nil?
          raise ArgumentError, "query must start with ?, or be a Regex" unless query[0] == ??
          query = Regexp.new("^\?#{Regexp.quote(query)}$", nil, 'n')
        end
        
        unless host.is_a? Regexp or host.nil?
          host = Regexp.new("^#{Regexp.quote(host)}$", true, 'n')
        end
        
        return unless (host.nil? or url.host =~ host) and
                      (path.nil? or url.path =~ path) and
                      (query.nil? or url.query =~ query) and
                      selectors.all? { |s| !doc.search(s).empty? }
        
        instance_eval(&block)
        @matched = true
      end
    end
    
    #
    # Adds all links which match *selector* to the crawl queue immediately
    #
    def crawl(selectors)
      selectors = Array(selectors)
      selectors.each do |s|
        doc.search(s).each do |a|
          href = a['href']
          next if href.nil? or href.empty?
          abs = to_absolute(URI(href)) # rescue next
          self.class.enqueue(abs, :referer => url.to_s, :depth => depth+1)
        end
      end
    end
    
    def follow(selector, &block)
      
    end
    
    #
    # Schedule a re-crawl this at *time*. If a re-crawl is already scheduled, change it.
    # +nil+ cancels any existing recrawl.
    #
    def recrawl(time)
      
    end
    
    #
    # URI object for the URL for the page
    #
    def url
      @url ||= URI(visit.url)
    end
    
    #
    # Depth of the current crawler
    #
    def depth
      @depth
    end
    
    #
    # The visit object for the current crawler
    #
    def visit
      @visit
    end
    
    #
    # Nokogiri document for the HTML body
    #
    def doc
      @doc ||= Nokogiri::HTML(visit.body) if visit.body and visit.html? # rescue nil
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