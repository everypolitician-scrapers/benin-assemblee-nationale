#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :members do
    member_urls.map do |url|
      begin
        Scraped::Scraper.new(url => MemberPage).scraper.to_h
      rescue OpenURI::HTTPError => error
        warn "#{url}: #{error}"
      end
    end.compact
  end

  private

  def member_urls
    noko.css('table tr td.column-1 a/@href').map(&:text).uniq
  end
end

class MemberPage < Scraped::HTML
  decorator Scraped::Response::Decorator::CleanUrls

  field :id do
    url.split('/').last
  end

  field :name do
    noko.css('title').text.split('|').first.tidy
  end

  field :given_name do
    info['Prénom']
  end

  field :family_name do
    info['Nom']
  end

  field :gender do
    info['Genre'].to_s.chr
  end

  field :email do
    info['Courriel']
  end

  field :photo do
    noko.css('.panel-layout img/@src').text
  end

  field :party do
    info['Groupe parlementaire']
  end

  field :constituency_id do
    info['Circonscription électorale']
  end

  field :constituency do
    info['Département']
  end

  field :source do
    url
  end

  private

  def info
    @info ||= noko.css('.panel-layout p')
                  .map(&:text)
                  .select { |p| p.include? ':' }
                  .map { |p| p.split(':', 2).map(&:tidy) }
                  .to_h
                  .reject { |_, v| v == '–' }
  end
end

url = 'https://assemblee-nationale.bj/index.php/depute/menu-liste-des-deputes/liste-des-deputes/'
Scraped::Scraper.new(url => MembersPage).store(:members)
