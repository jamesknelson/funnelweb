require 'logger'
require 'colorize'

module Funnelweb
  class Logger < ::Logger
    def initialize(name, output)
      super(output)
      
      self.formatter = proc do |severity, datetime, progname, msg|
        color = case severity
        when "FATAL"; :red
        when "ERROR"; :red
        when "WARN";  :yellow
        when "DEBUG"; :white
        else :light_white
        end
        "#{msg}\n".send(color)
      end
    end
    
  end
  
  mattr_accessor :logger
  @@logger = Logger.new(name, $stdout)
end