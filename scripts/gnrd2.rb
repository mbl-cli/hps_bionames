#!/usr/bin/env ruby

require 'karousel'
require 'rest_client'
require 'find'
require 'json'

class Page < Karousel::ClientJob
  NAME_FINDER_URL = 'http://gnrd.globalnames.org/name_finder.json'
  attr_accessor :status

  @@instances = nil

  def self.populate(karousel_size)
    get_all_instances unless @@instances
    res = []
    karousel_size.times { res << @@instances.shift }
    res.compact
  end

  def self.get_all_instances
    @@instances = []
    files = Find.find('.').select {|i| i.match /\.tiff$/}
    files.each do |f|
      @@instances << Page.new(f)
    end
  end

  def initialize(page_file)
    @file = page_file
    @status = 1
  end

  def send
    puts "sending job %s out of %s instances" % [@file, @@instances.size]
    params = {:file => File.new(@file, 'r'), 
      :unique => "true", :verbatim => "false", 
      :detect_language => "false",
      :all_data_sources => 'true',
      :best_match_only => 'true',
      :preferred_data_sources => '1|3|4',
    }
    RestClient.post(NAME_FINDER_URL, params) do |response, request, result, &block|
      if [302, 303].include? response.code
        @url = response.headers[:location]
        true
      else
        false
      end
    end
  end

  def finished?
    puts "checking for %s from %s" % [@url, @file]
    @res = RestClient.get(@url)
    @names = JSON.parse(@res, :symbolize_names => true)[:names]
  end

  def process
    puts @file
    w = open(@file + '.json', 'w:utf-8')
    w.write(JSON.pretty_generate(JSON.parse(@res)))
    w.close
    puts "Items left: %s" % @@instances.size
  end
end

k = Karousel.new(Page, 5, 10)
k.run  do 
  puts k.seats
end
