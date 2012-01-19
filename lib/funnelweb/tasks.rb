require 'resque/tasks'

namespace :funnelweb do
  desc "Setup funnelweb for use"
  task :environment, :config do |t, args|
    config = args[:config] || 'config/funnelweb.rb'
    
    require 'funnelweb'
    require File.expand_path(config, Dir.pwd + '/')
  end
  
  desc "Add a specific crawl's entry point to the crawl queue"
  task :crawl, :crawler, :needs => :environment do |t, args|
    crawler = args[:crawler]
    
    if crawler.nil?
      raise StandardError.new("You didn't provide a crawler. Please provide a crawler, e.g. rake funnelweb:crawl[crawler_name]")
    else
      Funnelweb.crawl(crawler)
    end
  end
end

task "resque:setup" => "funnelweb:environment"