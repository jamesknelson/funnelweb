require 'rubygems'

require 'active_support/core_ext/module/attribute_accessors'
require	'active_support/core_ext/string/inflections'

require 'resque'

require 'funnelweb/version'
require 'funnelweb/exceptions'

module Funnelweb
  
  mattr_accessor :config
  @@config = {
    # Identify self as Anemone/VERSION
    :user_agent => "Funnelweb/#{Funnelweb::VERSION}",
  
    # Number of times HTTP redirects will be followed
    :redirect_limit => 5,
  
    # Obeys robots.txt unless +false+. Defaults to +true+.
    :obey_robots_txt => true,
  
    # By default, don't limit the depth of the crawl
    :depth_limit => nil,
  
    # No delay between requests
    :delay => nil,
  
    # Accept cookies from the server and send them back?
    :accept_cookies => true,

    # Skip any link with a query string? e.g. http://foo.com/?u=>user
    :skip_query_strings => false,
  
    # HTTP read timeout in seconds
    :http_read_timeout => nil,
    
    # Number of days a pageview is considered fresh for
    :fresh_days => 3,
    
    # Provide extra debugging info
    :verbose => false,
    
    # Provide a class to use for the visit model
    :visit_model => nil,
    
    # proxy server hostname 
    :proxy_host => nil,
    
    # proxy server port number
    :proxy_port => false,
  }

  #
  # Change gloabl Funnelweb configuration options
  #
  def self.configure(options)
    unless Funnelweb.config[:visit_model].nil? || options[:visit_model].nil?
      raise ArgumentError.new("Option visit_model is read-only once set. It has already been set to #{Funnelweb.config[:visit_model].to_s}.")
    end
    
    Funnelweb.config.merge!(options)
  end
  
  #
  # Load a crawler, and map it into the router
  #
  def self.crawler(name)
    require name.to_s.downcase
  end
  
  # 
  # Default way to configure Funnelweb
  # 
  def self.setup(&block)
    puts "Funnelweb #{Funnelweb::VERSION} Loaded"
    
    instance_eval(&block)
    
    # We cannot require this file before now as it requires Funnelweb.config[:visit_model]
    # to have been set to the class which will be used as our visit model
    require 'funnelweb/visit'
  end
  
  #
  # Enqueue a visit for the "entry" url of the given crawler
  #
  def self.crawl(name)
    begin
      klass = Kernel.const_get("#{name.to_s.classify}Crawler")
    rescue
      raise ArgumentError.new("The crawler you specified has not been loaded or does not exist.")
    end
    
    if klass.config[:entry].nil?
      raise ArgumentError.new("The crawler you specified does not have an entry point specified") 
    end
    
    puts "Enqueueing #{klass.config[:entry]}"
    Resque.enqueue(Crawler, klass.config[:entry], 1, :force => true)
  end
  
end