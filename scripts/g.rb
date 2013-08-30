#!/usr/bin/env ruby

require 'karousel'
require 'rest_client'
require 'find'
require 'json'

  NAME_FINDER_URL = 'http://gnrd.globalnames.org/name_finder.json'

def resolve
  file = ARGV[0]
  url = ''
  params = {:file => File.new(file, 'r'),
    :unique => "false", :verbatim => "true",
    :detect_language => "false",
    :all_data_sources => 'true',
    :return_content => 'true',
    :best_match_only => 'true',
    :preferred_data_sources => '12',
  }
    RestClient.post(NAME_FINDER_URL, params) do |response, request, result, &block|
      if [302, 303].include? response.code
        url = response.headers[:location]
        true
      else
        puts 'did not work out'
        false
      end
    end
  sleep(60)
  res = RestClient.get(url)
  w = open(file + '.json', 'w:utf-8')
  w.write(JSON.pretty_generate(JSON.parse(res)))
  w.close
end

resolve
