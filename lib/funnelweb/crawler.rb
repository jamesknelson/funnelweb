require 'active_support/core_ext/class/attribute_accessors'

module Funnelweb
  class Crawler
    
    # Obeys robots.txt unless +false+. Defaults to +true+.
    cattr_accessor :obey_robots_txt
    @@obey_robots_txt = true
    
    # If set to an integer more than 0, each waits x milliseconds after retrieving a page
    # before going to the next job
    cattr_accessor :delay
    @@delay = 0

    # 
    # Configure the settings for a crawler
    # 
    def self.configure
      yield self
    end
    
  end
end