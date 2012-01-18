require 'net/https'
require 'funnelweb/page'
require 'funnelweb/exceptions'

module Funnelweb
  class Visit
    @queue = :crawler
    
    def self.perform(url, options = {})
      puts "Visiting #{url.to_s}"
      
      depth = options.delete(:depth) || 1
      
      # Find the crawler to use from the routes system
      crawler = Routing.crawler(url).new
      
      # If the URL exists in the page database, check its last crawled time
      page = Page.order(:created).where(:url => url.to_s).first
      
      # If the time is before page.fresh_until, don't crawl unless options[:force] is true
      if page.nil? or page.fresh_until < Time.now or options[:force]
        
        # Download the page
        response = get(url, options)
        
        Page.new  :url => location,
                  :body => response.body.dup,
                  :code => code,
                  :headers => response.to_hash,
                  :referer => referer,
                  :depth => depth,
                  :redirect_to => redirect_to,
                  :response_time => response_time

        # Create node and pass it to the crawler
        crawler.process(Node.new(page))
      end
    end
    
    private
    
    def self.get(url, options = {}, redirection_depth = 1)
      if redirection_depth > options[:redirection_limit]
        raise RedirectionLoopException,
          "HTTP Redirection loop detected with #{redirection_depth} redirects for url #{url}."
      end

      url = URI.parse(uri_str)
      req = Net::HTTP::Get.new(url.path, { 'User-Agent' => ua })
      response = Net::HTTP.start(url.host, url.port) { |http| http.request(req) }
      case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then fetch(response['location'], limit - 1)
      else
        response.error!
      end
    end

    #
    # Retrieve HTTP responses for *url*, including redirects.
    # Yields the response object, response code, and URI location
    # for each response.
    #
    def self.get(url, referer = nil)
      limit = redirect_limit
      loc = url
      begin
          # if redirected to a relative url, merge it with the host of the original
          # request url
          loc = url.merge(loc) if loc.relative?

          response, response_time = get_response(loc, referer)
          code = Integer(response.code)
          redirect_to = response.is_a?(Net::HTTPRedirection) ?  URI(response['location']).normalize : nil
          yield response, code, loc, redirect_to, response_time
          limit -= 1
      end while (loc = redirect_to) && allowed?(redirect_to, url) && limit > 0
    end

    #
    # Get an HTTPResponse for *url*, sending the appropriate User-Agent string
    #
    def self.get_response(url, referer = nil)
      full_path = url.query.nil? ? url.path : "#{url.path}?#{url.query}"

      opts = {}
      opts['User-Agent'] = user_agent if user_agent
      opts['Referer'] = referer.to_s if referer
#      opts['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)

      retries = 0
      begin
        start = Time.now()
        # format request
        req = Net::HTTP::Get.new(full_path, opts)
        # HTTP Basic authentication
        req.basic_auth url.user, url.password if url.user
        response = connection(url).request(req)
        finish = Time.now()
        response_time = ((finish - start) * 1000).round
        @cookie_store.merge!(response['Set-Cookie']) if accept_cookies?
        return response, response_time
      rescue Timeout::Error, Net::HTTPBadResponse, EOFError => e
        puts e.inspect if Funnelweb.config[:verbose]
        refresh_connection(url)
        retries += 1
        retry unless retries > 3
      end
    end

    def self.connection(url)
      @@connections[url.host] ||= {}

      if conn = @@connections[url.host][url.port]
        return conn
      end

      refresh_connection url
    end

    def self.refresh_connection(url)
      http = Net::HTTP.new(url.host, url.port, proxy_host, proxy_port)

      http.read_timeout = read_timeout if !!read_timeout

      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @@connections[url.host][url.port] = http.start 
    end

    #
    # Allowed to connect to the requested url?
    #
    def self.allowed?(to_url, from_url)
      to_url.host.nil? || (to_url.host == from_url.host)
    end
    
  end
end