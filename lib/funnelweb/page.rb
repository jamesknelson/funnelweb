require 'active_support/concern'
require 'webrick/cookie'

module Funnelweb
  module Page
    extend ActiveSupport::Concern
    
    included do
      include Mongoid::Document
      include Mongoid::Timestamps::Created
      
      belongs_to :resource, polymorphic: true

      field :url,           type: String
      field :body,          type: Binary
      field :headers,       type: Hash

      field :code,          type: String
      field :visited,       type: DateTime, :default -> { Time.now }
      field :referer,       type: String
      field :redirect_to,   type: String
      field :response_time, type: Float
      field :fetched,       type: Boolean
    end

    #
    # Create a new page
    #
    def initialize(url, params = {})
      self.url = url
      self.body = params[:body]
      self.headers = params[:headers] || {}
      self.headers['content-type'] ||= ['']

      self.code = params[:code]
      self.referer = params[:referer]
      self.redirect_to = to_absolute(params[:redirect_to])
      self.response_time = params[:response_time]
      self.fetched = !params[:code].nil?
      
      @aliases = Array(params[:aka]).compact
      @error = params[:error]
    end

    #
    # Was the page successfully fetched?
    # +true+ if the page was fetched with no error, +false+ otherwise.
    #
    def fetched?
      fetched
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

  end
end