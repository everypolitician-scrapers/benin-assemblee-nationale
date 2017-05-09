#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

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
  noko = noko_for(URI.encode(url))
  cell = ->(id) { noko.css("#cbfv_#{id}").text.tidy }
  data = {
    id:          url.split('/').last,
    name:        noko.css('#cbProfileTitle').text.tidy,
    family_name: cell.call(48),
    given_name:  cell.call(46),
    gender:      gender(cell.call(122)),
    # JS protected
    # email: cell.call(50),
    party:       cell.call(91),
    faction:     cell.call(92),
    faction_id:  cell.call(92).gsub(/[\,\-]/, '').gsub(/\s+/, '_').downcase,
    area_id:     cell.call(95),
    area:        cell.call(96),
    statut:      cell.call(97),
    image:       noko.css('#cbfv_29 img/@src').text,
    term:        7,
    source:      url,
  }
  # puts data
  ScraperWiki.save_sqlite(%i(id term), data)
end

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
scrape_list('http://www.assemblee-nationale.bj/fr/deputes/listes-des-deputes')
