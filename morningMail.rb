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
  puts game.css(".details").text
  ['away','home'].each do |l|
    puts game.css(".#{l} .team").text + game.css(".score .#{l}").text
  end
  empty_line
end

def print_elem(doc, class_name)
  puts doc.css(class_name).text.lstrip.rstrip 
end

def print_recap(url)
  doc = Nokogiri::HTML(open("http://sports.yahoo.com#{url}"))
  print_elem(doc, '.summary-text')
  print_elem(doc, '.summary')
  empty_line
end

def print_sport(sport, team, add_date=true)
  puts "\n#{sport.gsub('-',' ').upcase}"
  yesterday = (Date.today - 1).strftime "%Y-%m-%d" 
  url = "http://sports.yahoo.com/#{sport}/scoreboard/?date="
  url += yesterday if add_date

  doc = Nokogiri::HTML(open(url))
  doc.css('.game').each do |g|
    data_url = g.attr('data-url').to_s
    if data_url.match(yesterday.gsub('-',''))
      process_game g 
      print_recap(data_url) if data_url.match(team)
    end
  end
end

def print_tennis
  yesterday = (Date.today - 1).strftime "%Y%m%d" 
  url = "http://espn.go.com/tennis/dailyResults?date=#{yesterday}&matchType=msingles"
  doc = Nokogiri::HTML(open(url))
  last_event_title = ''
  doc.css('.matchContainer').each do |m|
    event = m.parent
    until event.attr('class') == 'scoreHeadline'
      event = event.previous
    end
    event_title = event.css('a').text 
    puts event_title unless event_title == last_event_title
    last_event_title = event_title

    first_winner = '*'
    second_winner = "" 
    if m.css('.arrow').attr('style').value.match /43/
      second_winner = "*" 
      first_winner = ''
    end

    printf "%-1s%-25s %s\n", first_winner, m.css('.teamLine a').text, (m.css('.lsLine2').map { |s| s.text }).join(' ')
    printf "%-1s%-25s %s\n", second_winner, m.css('.teamLine2 a').text, (m.css('.lsLine3').map { |s| s.text }).join(' ')
    empty_line
  end
end

print_weather
print_sport('college-basketball', 'michigan-wolverines')
#print_sport('nfl', 'chicago-bears', false)
print_sport('nba', 'chicago-bulls')
print_sport('nhl', 'chicago-blackhawks')
print_tennis
