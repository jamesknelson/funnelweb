require 'net/https'

module Funnelweb
  class ConnectionPool
    
    attr_accessor :options
    
    def initialize(opts)
      self.options = Funnelweb.config.merge(opts)
      @connections = {}
    end
    
    def connection(url)
      @connections[url.host] ||= {}

      if conn = @connections[url.host][url.port]
        return conn
      end

      refresh_connection url
    end

    def refresh_connection(url)
      http = Net::HTTP.new(url.host, url.port, options[:proxy_host], options[:proxy_port])

      http.read_timeout = options[:http_read_timeout] unless options[:http_read_timeout].nil?

      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @connections[url.host][url.port] = http.start 
    end
  end
end