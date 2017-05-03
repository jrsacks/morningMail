#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def append(text)
  @output += text + "\n"
end

def empty_line
  append ""
end

def weather_req(type, city, state)
  wunderground_key = File.open(File.dirname(__FILE__) + "/wunderground.key").read.chomp
  JSON.parse(open("http://api.wunderground.com/api/#{wunderground_key}/#{type}/q/#{state}/#{city}.json").read)
end

def print_weather(city, state)
  append "Weather for #{city}, #{state}"
  weather_req("hourly", city, state)['hourly_forecast'].slice(0,16).each do |hour|
    append hour['FCTTIME']['civil'].rjust(8) + " " + hour['temp']['english'].ljust(4) + hour['condition']
  end
  empty_line

  weather_req("forecast", city, state)['forecast']['txt_forecast']['forecastday'].slice(0,4).each do |day|
    append day['title'] + ":"
    day['fcttext'].split('.').each do |line|
      line.split('and').each do |part|
        append part
      end
    end
    empty_line
  end
end

def print_sport(sport, recaps=[])
  append "\n#{sport.upcase}"
  yesterday = (Date.today - 1).strftime "%Y-%m-%d"
  url = "https://api-secure.sports.yahoo.com/v1/editorial/s/scoreboard?leagues=#{sport}&date=#{yesterday}"
  url += "&top25=1" if sport.match(/ncaa/)

  data = JSON.parse(open(url).read)
  games = data["service"]["scoreboard"]["games"].map do |gameid, game|
    ["away","home"].map do |l|
      id = game["#{l}_team_id"]
      team_name = data["service"]["scoreboard"]["teams"][id]["full_name"]
      periods = game["game_periods"].map do |periods|
        (periods["#{l}_points"] || "")
      end
      if sport == 'mlb'
        stats = game["#{l}_team_stats"]
        team_name + " " + periods.join(' ').ljust(26) + stats[0]["runs"].rjust(2) + " " + stats[1]["hits"].rjust(2) + " " + stats[2]["errors"]
      else
        team_name + " " + periods.join(' ').ljust(20) + game["total_#{l}_points"]
      end
    end
  end

  games.each_with_index do |g, idx|
    append g[0]
    append g[1]
    game = data["service"]["scoreboard"]["games"].values[idx]
    teams = data["service"]["scoreboard"]["teams"]
    if recaps.include?(teams[game["home_team_id"]]["full_name"]) || recaps.include?(teams[game["away_team_id"]]["full_name"])
      gameId = game["gameid"]
      url = "https://sports.yahoo.com/site/api/resource/sports.game.articles;id=#{gameId}"
      begin
        append JSON.parse(open(url).read)["gamearticles"][gameId]["recap"]["summary"]
      rescue =>e
        STDERR.puts e
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
    append event_title unless event_title == last_event_title
    last_event_title = event_title

    first_winner = '*'
    second_winner = "" 
    if m.css('.teamLine2 .arrowWrapper').length > 0
      second_winner = "*" 
      first_winner = ''
    end

    append(sprintf "%-1s%-25s %s", first_winner, m.css('.teamLine a').text, (m.css('.lsLine2').map { |s| s.text }).join(' '))
    append(sprintf "%-1s%-25s %s", second_winner, m.css('.teamLine2 a').text, (m.css('.lsLine3').map { |s| s.text }).join(' '))
    empty_line
  end
end

Dir.glob("data/*") do |file|
  @output = ''
  config = JSON.parse(File.read(file))
  config["weather"].each do |location|
    print_weather(location["city"], location["state"])
  end
  config["sports"].each do |sport|
    begin
      if sport["name"] == "tennis"
        print_tennis
      else
        print_sport(sport["name"], sport["recaps"])
      end
    rescue => e
    end
  end
  system("mail -s 'Morning Mail' #{config["email"]} <<DOC\n#{@output}\nDOC")
end
