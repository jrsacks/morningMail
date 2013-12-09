#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def empty_line
  puts ""
end

def weather_req(type, city="Chicago", state="IL")
  wunderground_key = File.open(File.dirname(__FILE__) + "/wunderground.key").read.chomp
  JSON.parse(open("http://api.wunderground.com/api/#{wunderground_key}/#{type}/q/#{state}/#{city}.json").read)
end

def print_weather
  weather_req("forecast")['forecast']['txt_forecast']['forecastday'].slice(0,4).each do |day|
    puts day['title'] + ":"
    day['fcttext'].split('.').each do |line|
      puts "\t#{line}"
    end
  end

  empty_line
  weather_req("hourly")['hourly_forecast'].slice(0,16).each do |hour|
    puts hour['FCTTIME']['civil'] + " " + hour['temp']['english'] + " " + hour['condition']
  end
end

def process_game(game)
  ['away','home'].each do |l|
    puts game.css(".#{l} .team").text + game.css(".score .#{l}").text
  end
  empty_line
end

def print_sport(sport, add_date=true)
  puts "\n#{sport.gsub('-',' ').upcase}"
  yesterday = (Date.today - 1).strftime "%Y-%m-%d" 
  url = "http://sports.yahoo.com/#{sport}/scoreboard/?date="
  url += yesterday if add_date

  doc = Nokogiri::HTML(open(url))
  doc.css('.game').each do |g|
    process_game g if g.attr('data-url').to_s.match(yesterday.gsub('-',''))
  end
end


print_weather
print_sport('college-basketball')
print_sport('nfl', false)
print_sport('nba')
print_sport('nhl')
