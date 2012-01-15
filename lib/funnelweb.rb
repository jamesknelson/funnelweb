require 'rubygems'

require 'active_support/core_ext/module/attribute_accessors'

require "funnelweb/version"
require 'funnelweb/core'

module Funnelweb
  
  # Identify self as Anemone/VERSION
  mattr_accessor :user_agent
  @@user_agent = "Funnelweb/#{Anemone::VERSION}",
  
  # Number of times HTTP redirects will be followed
  mattr_accessor :redirect_limit
  @@redirect_limit = 5
  
  # Obeys robots.txt unless +false+. Defaults to +true+.
  mattr_accessor :obey_robots_txt
  @@obey_robots_txt = true
  
  # By default, don't limit the depth of the crawl
  mattr_accessor :depth_limit
  @@depth_limit = nil
  
  # No delay between requests
  mattr_accessor :delay
  @@delay = nil
  
  # Accept cookies from the server and send them back?
  mattr_accessor :accept_cookies
  @@accept_cookies = true

  # Skip any link with a query string? e.g. http://foo.com/?u=user
  mattr_accessor :skip_query_strings
  @@skip_query_strings = false
  
  # HTTP read timeout in seconds
  mattr_accessor :http_read_timeout
  @@http_read_timeout = nil
  
  # 
  # Default way to configure Funnelweb
  # 
  def self.configure
    yield self
  end
  
end