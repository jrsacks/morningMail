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
  weather_req("hourly")['hourly_forecast'].slice(0,16).each do |hour|
    puts hour['FCTTIME']['civil'] + " " + hour['temp']['english'] + " " + hour['condition']
  end
  empty_line

  weather_req("forecast")['forecast']['txt_forecast']['forecastday'].slice(0,4).each do |day|
    puts day['title'] + ":"
    day['fcttext'].split('.').each do |line|
      puts "\t#{line}"
    end
  end
end

def print_sport(sport)
  puts "\n#{sport.upcase}"
  yesterday = (Date.today - 1).strftime "%Y-%m-%d"
  url = "http://sports.yahoo.com/ysmobile/_td_api/resource/sportacular-web-scores-store/id/scoreboard;path%3D%7B%22game%22%3A%22#{sport}%22%2C%22date%22%3A%22#{yesterday}%22%7D"

  data = JSON.parse(open(url).read)
  games = []
  if data["result"]["games"].is_a? Array
    games = data["result"]["games"].map do |game|
      ["away","home"].map do |l|
        team_name = game['teams']["#{l}_team"]["abbr"].ljust(4)
        periods = if game['total_score']["game_periods"]["game_period"].is_a? Array
          game['total_score']["game_periods"]["game_period"].map do |periods|
            (periods["#{l}_points"] || "")
          end
        else
          []
        end
        if sport == 'mlb'
          stats = game['total_score']["#{l}_team_stats"]
          team_name + " " + periods.join(' ').ljust(26) + stats["runs"].rjust(2) + " " + stats["hits"].rjust(2) + " " + stats["errors"]
        else
          team_name + " " + periods.join(' ').ljust(20) + game["total_score"]["total_#{l}_points"]
        end
      end
    end
  end

  games.each_with_index do |g, idx|
    puts g[0]
    puts g[1]
    if (g[0] + g[1]).match(/Chi/)
      gameId = data["result"]["games"][idx]["game_id"].gsub("#{sport}.g.","")
      url = "http://sports.yahoo.com/ysmobile/_td_api/resource/sportacular-web-game-store/id/game-detail;force=true;gType=#{sport};where=%7B%22gameId%22%3A%22#{gameId}%22%7D"
      begin
        puts JSON.parse(open(url).read)["article"]["summary"]
      rescue =>e
      end
    end
    empty_line
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
print_sport("mlb")
print_sport("nba")
print_sport("nhl")
print_tennis
