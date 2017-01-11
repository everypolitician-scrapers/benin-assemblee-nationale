#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('#cbUserTable td.cbUserListCol1').each do |row|
    mp_url = row.css('.cbUserListFC_firstname a/@href').text
    scrape_mp(mp_url)
  end
end

def gender(str)
  return if str.nil? || str.empty?
  return 'male' if str.downcase == 'masculin'
  return 'female' if str.downcase == 'féminin'
  raise "unexpected gender: #{str}"
end

def scrape_mp(url)
  noko = noko_for(URI.encode url)
  cell = ->(id) { noko.css("#cbfv_#{id}").text.strip }
  data = { 
    id: url.split('/').last,
    name: noko.css('#cbProfileTitle').text.strip,
    family_name: cell.(48),
    given_name: cell.(46),
    gender: gender(cell.(122)),
    # JS protected
    # email: cell.(50),
    party: cell.(91),
    faction: cell.(92),
    faction_id: cell.(92).gsub(/[\,\-\–]/,'').gsub(/\s+/, '_').downcase,
    area_id: cell.(95),
    area: cell.(96),
    statut: cell.(97),
    image: noko.css('#cbfv_29 img/@src').text,
    term: 7,
    source: url
  }
  puts "#{data[:id]} -> #{data[:faction]} = #{data[:faction_id]}"
  ScraperWiki.save_sqlite([:id, :term], data)
end

scrape_list('http://www.assemblee-nationale.bj/fr/deputes/listes-des-deputes')
