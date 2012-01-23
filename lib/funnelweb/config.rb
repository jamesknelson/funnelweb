require 'active_support/core_ext/module/attribute_accessors'

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
   logger.info "Funnelweb #{Funnelweb::VERSION}".light_magenta

   instance_eval(&block)

   # We cannot require these files before now as it requires Funnelweb.config[:visit_model]
   # to have been set to the class which will be used as our visit model
   require 'funnelweb/visit'
   require 'funnelweb/crawler'
 end
end