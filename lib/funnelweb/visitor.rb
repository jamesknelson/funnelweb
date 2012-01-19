require 'URI'

require 'funnelweb/visit'

module Funnelweb
  class Visitor
    @queue = :crawler
    
    attr_accessor :url
    attr_accessor :options
    attr_accessor :crawler
    attr_accessor :recent_page
    
    attr_accessor :redirections
    attr_accessor :response
    attr_accessor :code
    attr_accessor :final_url
    attr_accessor :errors
    attr_accessor :response_time
    
    
    #
    # This is called by Resque workers to start the proces of a visit 
    #
    def self.perform(url, depth, options = {})
      Visit.new(url, depth, options = {})
    end
    
    
    def initialize(link, depth, opts = {})
      # Find the crawler to use from the routes system and bring in it's configuration
      self.crawler = Routing.crawler(link).new
      self.recent_page = Page.find_most_recent_crawl(link)
      self.url = URI(link)
      self.options = Funnelweb.config.merge(crawler.config.merge(opts))
      self.redirections = 0
      self.errors = []
      
      if depth > options[:depth_limit]
        # Raise an exception, as this is probably an error with the crawler, not the site
        raise StandardError.new("Depth is #{depth}, which is higher than allowed depth #{options[:depth_limit]}")
      end

      response = get()      
      # Only crawl if the page is not fresh anymore
      
      if self.errors.empty? 
        # Download the page
        
        Page.new  :url => location,
                  :body => response.body.dup,
                  :code => code,
                  :headers => response.to_hash,
                  :referer => referer,
                  :redirect_to => redirect_to,
                  :response_time => response_time

        # Create node and pass it to the crawler
        crawler.process(Node.new(page))
      end
    end
    
    def visit?(link)
      self.errors = []
      
      self.errors << "Page is still fresh, will not check again until #{recent_page.fresh_until.to_s}" unless recent_page.nil? or recent_page.fresh_until < Time.now or options[:force]
      self.errors << "Page is disallowed by robots.txt" unless crawler.class.robots_allowed?(link)
      self.errors << "Skipping pages with query strings" unless options[:skip_query_strings].nil? || !link.query
      self.errors << "Not following link to different host" unless link.host.nil? || (url.host == link.host)
      self.errors << "#{redirections} redirections were made with a limit of #{options[:redirect_limit]}" if !options[:redirect_limit].nil? and redirections > options[:redirect_limit]
      
      self.errors.empty?
    end
    
    private
    
    #
    # Retrieve HTTP response for *url*, and changes the class to reflect this
    # Yields response, code, link, redirect_to, response_time for each redirection
    # Returns true if a final url was retrieved without error, false otherwise
    #
    def get
      link = url.clone
      self.final_url = nil
      self.redirections = 0
            
      headers = {}
      headers['User-Agent'] = options[:user_agent]
      headers['Referer'] = options[:referer] unless options[:referer].nil?
      #headers['Cookie'] = @cookie_store.to_s unless @cookie_store.empty? || (!accept_cookies? && @opts[:cookies].nil?)
      
      begin
        if !visit?(link)
          puts "Skipping #{url}:\n" + @errors.join("\n")
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
          self.response = crawler.class.connection_pool.connection(link).request(req)
          finish = Time.now()
          self.response_time = ((finish - start) * 1000).round
          #@cookie_store.merge!(response['Set-Cookie']) if accept_cookies?
        rescue Timeout::Error, Net::HTTPBadResponse, EOFError => e
          puts e.inspect if Funnelweb.config[:verbose]
          crawler.class.connection_pool.refresh_connection(link)
          retries += 1
          if retries > 3
            # Raise an exception here instead of add to @errors, as connections
            # timing out are outside the scope of the application
            raise e
          else
            retry
          end
        end
        
        self.code = Integer(response.code)
        redirect_to = if response.is_a?(Net::HTTPRedirection)
          self.redirections += 1
          link = redirect_to
          URI(response['location']).normalize
        end
        
        # TODO: check if a block exists before yielding
        # yield response, code, link, redirect_to, response_time if 
        
      end while !redirect_to.nil?
      
      self.final_url = link
      true
    end # get
    
  end # Visit
end # Funnelweb