require 'active_support/concern'
require 'active_support/core_ext/numeric/time'

require 'webrick/cookie'

require 'mongoid'

module Funnelweb
  module Mongoid
    module Visit
      extend ::ActiveSupport::Concern
    
      included do
        include ::Mongoid::Document
        include ::Mongoid::Timestamps::Created
        
        has_one :redirect_to
        belongs_to :redirected_from, :class_name => 'Participant'
        
        # Request
        field :url,           type: String
        field :referer,       type: String
        field :method,        type: String
        field :data,          type: String
        
        # Response
        field :code,          type: Integer
        field :body,          type: String
        field :headers,       type: Hash
        field :response_time, type: Float

        # Other
        field :fresh_until,   type: DateTime, default: -> { |o| Time.now + o.options[:fresh_days].days }
        field :errors,        type: Hash
        
      end
    
    
      module ClassMethods
        def find_most_recent_crawl(url)
          where(:url => url.to_s).order_by(:created).desc.first
        end
      end

    
      def headers=(headers)
        self.headers = headers || {}
        self.headers['content-type'] ||= ['']
      end

      #
      # Array of cookies received with this page as WEBrick::Cookie objects.
      #
      def cookies
        WEBrick::Cookie.parse_set_cookies(headers['Set-Cookie']) rescue []
      end

      #
      # The content-type returned by the HTTP request for this page
      #
      def content_type
        headers['content-type'].first
      end

      #
      # Returns +true+ if the page is a HTML document, returns +false+
      # otherwise.
      #
      def html?
        !!(content_type =~ %r{^(text/html|application/xhtml+xml)\b})
      end

      #
      # Returns +true+ if the page is a HTTP redirect, returns +false+
      # otherwise.
      #
      def redirect?
        (300..307).include?(code)
      end

      #
      # Returns +true+ if the page was not found (returned 404 code),
      # returns +false+ otherwise.
      #
      def not_found?
        404 == code
      end
      
      #
      # Returns +true+ if the page was successfully fetched (returned code 200),
      # returns +false+ otherwise.
      #
      def fetched?
        200 == code
      end

    end
  end
end