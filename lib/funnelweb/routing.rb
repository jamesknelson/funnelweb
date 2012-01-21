require 'active_support/core_ext/class/attribute_accessors'

module Funnelweb
  ##
  # This class is an extended version of Rack::URLMap, based on the Padrino version
  #
  # Funnelweb::Router will go through the various mappings in order, and dispatch 
  # to the first one which matches.
  #
  # Features:
  #
  # * Map a path and/or host to the specified Crawler
  # * Ignore server names (this solve issues with vhost and domain aliases)
  # * Use hosts instead of server name for mappings (this help us with our vhost and doman aliases)
  #
  # @example
  #
  #   routes = Funnelweb::Routing.setup do
  #     map :host => /*.amazon.com/, :path => '/books-used-books-textbooks', :to => AmazonBooksCrawler
  #     map :host => "www.bookdepository.co.uk", :to => BookDepositoryCrawler
  #   end
  #
  # @api semipublic
  class Routing
    
    cattr_accessor :mapping
    @@mapping = []
    
    class << self
      
      # Called from configuration files to setup the routing
      def setup(*mapping, &block)
        mapping.each { |m| map(m) }
        class_eval(&block) if block
      end
      
      ##
      # Map a route path and host to a specified application.
      #
      # @param [Hash] options
      #  The options to map.
      # @option options [Funnelweb::Crawler] :to
      #  The class of the application to mount.
      # @option options [String/Regexp] :path ("/")
      #  The path to map the specified application.
      # @option options [String/Regexp] :host
      #  The host to map the specified application.
      #
      # @example
      #  map :host => /*.amazon.com/, :path => '/books-used-books-textbooks', :to => AmazonBooksCrawler
      #
      # @return [Array] The route mappings.
      # @api semipublic
      def map(options={})
        path = options[:path]
        host = options[:host]
        crawler  = options[:to]

        raise ArgumentError, "paths need to start with /" unless path.nil? or path.is_a? Regexp or path[0] == ?/
        raise ArgumentError, "crawler must be a class" if crawler.nil? or !crawler.is_a? Class

        path  = path.chomp('/') unless path.nil?
        match = Regexp.new("^#{Regexp.quote(path).gsub('/', '/+')}\/?$", nil, 'n') unless path.nil? || path.is_a?(Regexp)
        host  = Regexp.new("^#{Regexp.quote(host)}$", true, 'n') unless host.nil? || host.is_a?(Regexp)

        @@mapping << [host, path, match, crawler]
      end
      
      # Comares a given request to the routing map and returns the appropriate crawler class. 
      # @api private
      def crawler(url)
        uri = URI(url) unless url.is_a? URI
        @@mapping.each do |host, path, match, crawler|
          next unless host.nil? || uri.host =~ host
          next unless path.nil? || uri.path =~ match

          return crawler
        end
      end
      
    end
  end
end
