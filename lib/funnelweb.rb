require 'rubygems'

require 'active_support/core_ext/module/attribute_accessors'
require	'active_support/core_ext/string/inflections'

require 'resque'

require 'funnelweb/version'
require 'funnelweb/visit'

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
    :verbose => false
  }
  
  
  def self.configure(options)
    Funnelweb.config.merge!(options)
  end
  
  def self.crawler(name)
    require name.to_s.downcase
  end
  
  # 
  # Default way to configure Funnelweb
  # 
  def self.setup(&block)
    puts "Funnelweb #{Funnelweb::VERSION} Loaded"
    
    instance_eval(&block)
  end
  
  def self.rake
    require 'funnelweb/tasks'
  end
  
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
    Resque.enqueue(Visit, klass.config[:entry], :force => true)
  end
  
end