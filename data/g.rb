#!/usr/bin/env ruby

require 'rest_client'
require 'json'
require 'pp'

NAME_FINDER_URL = 'http://gnrd.globalnames.org/name_finder.json'
url = nil

params = {:file => File.new(ARGV[0], 'rb'), :unique => "true", :verbatim => "false", :detect_language => "false"}
res =   RestClient.post(NAME_FINDER_URL, params) do |response, request, result, &block|
    if [302, 303].include? response.code
      url = response.headers[:location]
      true
    else
      false
    end
  end
puts res
r = JSON.parse(url, symbolize_names: true)

pp r
