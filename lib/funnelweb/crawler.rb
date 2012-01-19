require 'net/https'
require 'robots'
require 'active_support/core_ext/class/attribute_accessors'

require 'funnelweb/routing'
require 'funnelweb/connection_pool'

module Funnelweb
  class Crawler
    
    cattr_accessor :config
    @@config = {}
    
    def self.connection_pool
      @@connection_pool
    end
    
    def self.robots_allowed?(url)
      config[:obey_robots_txt] ? @@robots.allowed?(url) : true
    end
    
    # 
    # Configure the settings for a crawler
    # 
    def self.configure(options)
      config.merge!(options)
      
      @@robots = Robots.new(config[:user_agent])
      @@connection_pool = ConnectionPool.new(config)
    end
    
    def self.map(options)
      Funnelweb::Routing.map(options.merge(:to => self))
    end
    
    def process
      raise NotImplemented
    end
    
  end
end