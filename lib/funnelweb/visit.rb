require 'delegate'

unless Funnelweb.config[:visit_model].is_a? Class
  raise ConfigurationError.new("Option visit_model needs to be set to a class.")
end

module Funnelweb
  class Visit < Funnelweb.config[:visit_model]

    
  end
end