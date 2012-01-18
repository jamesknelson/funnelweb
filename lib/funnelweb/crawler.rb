require 'active_support/core_ext/class/attribute_accessors'
require 'funnelweb/routing'

module Funnelweb
  class Crawler
    
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
    
    def process
      raise NotImplemented
    end
    
  end
end