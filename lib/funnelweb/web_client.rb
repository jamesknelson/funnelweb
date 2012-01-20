require 'URI'
require 'net/https'
require 'robots'

require 'funnelweb/visit'
require 'funnelweb/crawler'
require 'funnelweb/routing'

module Funnelweb
  class WebClient
    attr_accessor :visit
    
    @@connections = {}
    @@robots = Robots.new(Funnelweb.config[:user_agent])
    
    #
    # Visit the given url, following referers and yielding a new crawler object with
    # it's associated visit for each request/response
    #
    def self.get(address, referer, options={})
      # TODO: It would probably make more sense to get the crawler in crawler.rb, but I'm doing 
      #       it here because we need options from the crawler, and the crawler could change
      #       due to a redirect
      crawler_class = Routing.crawler(address)
      options = Funnelweb.config.merge(crawler_class.config.merge(options))
      
      url = URI(link)
      errors = []
      
      headers = {}
      headers['User-Agent'] = options[:user_agent]
      headers['Referer'] = options[:referer] unless options[:referer].nil?
      #headers['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)
      
      link = url.clone
      redirections = 0
      begin
        if !visit?(link)
          puts "Skipping #{url}:\n" + @errors.join("\n")
          # TODO: create visit record with reasons for skipping
          return false
        end
        
        puts "#{redirections == 0 ? 'Visiting' : 'Redirecting to'} #{link.to_s}"
      
        # if redirected to a relative url, merge it with the host of the original
        # request url
        link = url.merge(link) if link.relative?
        full_path = link.query.nil? ? link.path : "#{link.path}?#{link.query}"

        retries = 0
        begin
          start = Time.now()
          # Format Request
          req = Net::HTTP::Get.new(full_path, headers)
          # HTTP Basic authentication
          req.basic_auth link.user, link.password if link.user
          self.response = connection(link).request(req)
          finish = Time.now()
          self.response_time = ((finish - start) * 1000).round
          #@cookie_store.merge!(response['Set-Cookie']) if accept_cookies?
        rescue Timeout::Error, Net::HTTPBadResponse, EOFError => e
          puts e.inspect if Funnelweb.config[:verbose]
          refresh_connection(link)
          retries += 1
          if retries > 3
            # Raise an exception here instead of add to @errors, as connections
            # timing out are outside the scope of the application
            raise e
          else
            retry
          end
        end
        
        code = Integer(response.code)
        if response.is_a?(Net::HTTPRedirection)
          redirections += 1
          redirect_to = link = URI(response['location']).normalize
        else
          redirect_to = nil
        end
        
        # TODO: create visit and crawler containing visit
        
        yield crawler
        
      end while !redirect_to.nil?

      true
    end
    
    # TODO: integrate this better.
    def self.errors(link, options)
      errors = []
      
      recent_page = Page.find_most_recent_crawl(address)
      
      errors << "Page is still fresh, will not check again until #{recent_page.fresh_until.to_s}" unless recent_page.nil? or recent_page.fresh_until < Time.now or options[:force]
      errors << "Page is disallowed by robots.txt" unless crawler.class.robots_allowed?(link)
      errors << "#{redirections} redirections were made with a limit of #{options[:redirect_limit]}" if !options[:redirect_limit].nil? and redirections > options[:redirect_limit]
      errors << "Skipping pages with query strings" unless options[:skip_query_strings].nil? || !link.query
      errors << "Not following link to different host" unless link.host.nil? || (url.host == link.host)
      
      errors
    end
    
    private
    
    def self.connection(url)
      @@connections[url.host] ||= {}

      if conn = @@connections[url.host][url.port]
        return conn
      end

      refresh_connection url
    end

    def self.refresh_connection(url, options={})
      http = Net::HTTP.new(url.host, url.port, options[:proxy_host], options[:proxy_port])

      http.read_timeout = options[:http_read_timeout] unless options[:http_read_timeout].nil?

      if url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @@connections[url.host][url.port] = http.start 
    end
    
    #
    # Private helper method to check robots.txt
    #
    def self.robots_allowed?(url, options={})
      option[:obey_robots_txt] ? @@robots.allowed?(url) : true
    end
    
  end # Visit
end # Funnelweb