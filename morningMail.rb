#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

@wunderground_key = File.open("wunderground.key").read.chomp
def weather_req(type, city="Chicago", state="IL")
  JSON.parse(open("http://api.wunderground.com/api/#{@wunderground_key}/#{type}/q/#{state}/#{city}.json").read)
end

weather_req("forecast")['forecast']['txt_forecast']['forecastday'].slice(0,4).each do |day|
  puts day['title'] + ":"
  day['fcttext'].split('.').each do |line|
    puts "\t#{line}"
  end
end

puts "" #Spacing
weather_req("hourly")['hourly_forecast'].slice(0,16).each do |hour|
  puts hour['FCTTIME']['civil'] + " " + hour['temp']['english'] + " " + hour['condition']
end

def process_game(game)
  away = game.css('.away .team').text
  away_score = game.css('.score .away').text
  home = game.css('.home .team').text
  home_score = game.css('.score .home').text
  puts "#{away}: #{away_score}"
  puts "#{home}: #{home_score}"
  puts ""
end

yesterday = (Date.today - 1).strftime "%Y-%m-%d" 
["college-basketball", "nba", "nhl"].each do |sport|
  doc = Nokogiri::HTML(open("http://sports.yahoo.com/#{sport}/scoreboard/?date=#{yesterday}"))
  puts "\n#{sport.gsub('-',' ').upcase}"
  doc.css('.game').each { |g| process_game g }
end
