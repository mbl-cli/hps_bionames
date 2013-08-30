#!/usr/bin/env ruby

require 'mysql2'

class Stats

  def initialize
    @db = Mysql2::Client.new(host: 'localhost', username: 'root',
                             database: 'embryology')
  end

  def books_num
    @db.query("select count(*) as count from books").first["count"]
  end

  def names_num
    @db.query("select count(*) as count from canonical_forms").first["count"]
  end

end

s = Stats.new

puts "In %s volumes %s names had been found" % [s.books_num, s.names_num]


