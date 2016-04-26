load 'sibyl_conf.rb'

require 'rirc'

config = ConfigClass.new

#-------~-----~--~------~---~-------~----~------------~---~-----
# setup
#-------~-----~--~------~---~-------~----~------------~---~-----
network = config.acquire[:network]
port = config.acquire[:port]
pass = config.acquire[:pass]
nick = config.acquire[:nick]
username = config.acquire[:username]
realname = config.acquire[:realname]
nickserv_pass = config.acquire[:nickpass]
channels = config.acquire[:channels]
admins = config.acquire[:admins]
use_ssl = config.acquire[:SSL]
use_pass = config.acquire[:usepass]
plugin_folder = config.acquire[:plugindir]
plugins_list = config.acquire[:plugins]

bot = IRCBot.new(network, port, nick, username, realname)
bot.set_admins(admins)

# puts "Loading Plugins"
plug = Plugin_manager.new(plugin_folder)
# plugins_list.each { |a| t = plug.plugin_load(a); puts "		#{t}"; }

commands = Commands_manager.new
#-------~-----~--~------~---~-------~----~------------~---~-----

#-------~-----~--~------~---~-------~----~------------~---~-----
# Commands
#-------~-----~--~------~---~-------~----~------------~---~-----
commands.on /^\.list \S+$/ do |ircbot, ircmsg, pluginmgr|
	case ircmsg.message.split(" ")[1].to_s
	when /^plugins$/ then
		ircbot.privmsg(ircmsg.nick, "Plugins")
		pluginmgr.get_names.each do |name|
			ircbot.privmsg(ircmsg.nick, name)
		end
	when /^channels$/ then
		ircbot.privmsg(ircmsg.nick, "Channels")
		ircbot.channels.each do |name|
			ircbot.privmsg(ircmsg.nick, name)
		end
	end
end

commands.on /^\.join \S+$/ do |ircbot, ircmsg, pluginmgr|
	if not ircbot.admins.include? ircmsg.nick
		bot.privmsg(ircmsg.nick, "you are not an admin and cannot use .join")
	else
		bot.join(ircmsg.message.split(" ")[1].to_s)
	end
end
#-------~-----~--~------~---~-------~----~------------~---~-----

#-------~-----~--~------~---~-------~----~------------~---~-----
# actions for bot
#-------~-----~--~------~---~-------~----~------------~---~-----

# check commands
# check plugins
bot.on :message do |msg|
      commands.check_cmds(bot, msg, plug)

      responses = plug.check_all(msg, bot.admins, bot.backlog)
      responses.each { |a| bot.say(a) }
end

# hello
bot.on :message do |msg|
	case msg.message
	when /^[Hh]ello.? #{nick}([!\.]+)?$/ then
		bot.privmsg(msg.channel, "Hello: #{msg.nick}")
	when /^#{nick}. [Hh]ello([!\.]+)?$/
		bot.privmsg(msg.channel, "Hello: #{msg.nick}")
	end
end

# help
bot.on :message do |msg|
	case msg.message
	when /^#{bot.nick_name}.\s?source\??$/ then
		r = []
		r.push("sibyl source: https://github.com/The-Duchess/sibyl")
		r.push("sibyl is built on rirc which can be found on github: https://github.com/The-Duchess/ruby-irc-framework")
		r.each do |string|
			bot.privmsg(msg.nick, string)
		end
	when /^\.source$/ then
		r = []
		r.push("sibyl source: https://github.com/The-Duchess/sibyl")
		r.push("sibyl is built on rirc which can be found on github: https://github.com/The-Duchess/ruby-irc-framework")
		r.each do |string|
			bot.privmsg(msg.nick, string)
		end
	when /^\.help$/ then
		h = []
		h.push("commands:")
		h.push("	- .quote")
		h.push("	- .cmd")
		h.push("all commands have a help that can be accessed: $CMC --help")
		h.each do |string|
			bot.privmsg(msg.nick, string)
		end
	end
end

# cmd
bot.on :message do |msg|
	case msg.message
	when /^\.cmd --help$/ then
		bot.privmsg(msg.channel, ".cmd on [regex] do [cmd type] [args]. note the text \" on /\" cannot exist in the regex and \"/ do \" cannot be in the cmd type or args")
	when /^\.cmd on \/.*\/ do [a-zA-Z]\w+ (\w+ ?)+$/ then
		if bot.admins.include? msg.nick
			reg = "" # regex the user gave
			cmd = "" # the type of command the user gave [say | ..] # currently only say is provided
			arg = "" # the arg for the command the user gave

			# lex and parse input message
			token_o = msg.message.split(" on /")
			token_d = token_o[1].split("/ do ")
			reg = Regexp.new(token_d[0].to_s[0..-1].to_s)
			token_s = token_d[1].split(" ")
			cmd = token_s[0].to_s
			arg = token_s[1..-1]
			case cmd
			when /^say$/ then
				commands.on reg do |ircbot, ircmsg, pluginmgr|
					args = arg
					say_t = ""
					args.each { |text| say_t.concat("#{text} ") }
					say_t = say_t[0..-2].to_s
					ircbot.privmsg(ircmsg.channel, say_t)
				end
			when /^kick$/ then # .cmd on // do kick user chan reason
				commands.on reg do |ircbot, ircmsg, pluginmgr|
					args = arg
					user = args[0]
					chan = args[1]
					args = args[2..-1]
					say_t = ""
					args.each { |text| say_t.concat("#{text} ") }
					ircbot.say("KICK #{user}: #{say_t}")
				end
			end
			bot.privmsg(msg.channel, "command has been added")
		else
			bot.privmsg(msg.channel, "you are not an admin and this feature is currently only open for admins")
		end
	end
end

# stop
bot.stop! /^\.leave$/ do |msg|
    bot.channels.each do |channel|
    	bot.notice(channel, "leaving")
    end
end

def file file_

	@file = File.readlines(file_)
end

def save names_, quotes_

	File.open("./quotes.txt", 'w') do |fw|
		names_.each do |name|
			quotes_[name].each do |quote|
				fw.puts "#{name}:#{quote}"
			end
		end
	end
end

lines   = file "./quotes.txt"
names   = []
quotes  = {}
quotes_ = []

lines.each do |line|
	name  = line.split(":")[0]
	quote = line[(name.length+1)..-1]
	if !names.include? name
		names.push(name)
	end
	quotes[name] ||= []
	quotes[name] << quote
	quotes_ << "#{quote} - #{name}"
end

# quote
bot.on :message do |msg|


	case msg.message
	when /^\.quote --help$/ then
		bot.privmsg(msg.channel, ".quote --help | --random-name [name] | --random-quote [part of quote] | --random")
		bot.privmsg(msg.channel, "| --add [name] [text] | --save")
	when /^\.quote --random-name (\S+)$/ then
		name_ = msg.message.split(" ")[2]
		if names.include? name_
			match_ = quotes[name_]
			i = rand(match_.length) - 1
			i_ = match_[i]
			bot.privmsg(msg.channel, i_)
		end
	when /^\.quote --random-quote (\S+ ?)+$/ then
		match_ = []
		search_ = msg.message[22..-1]
		quotes_.each do |quote|
			if quote.split("-")[0].to_s.include? search_
				match_.push(quote)
			end
		end
		i = rand(match_.length) - 1
		i_ = match_[i]
		bot.privmsg(msg.channel, i_)
	when /^\.quote --random$/ then
		i = rand(quotes_.length) - 1
		i_ = quotes_[i]
		bot.privmsg(msg.channel, i_)
	when /^\.quote --add (\S+) (\S+ ?)+$/ then
		name_ = msg.message.split(" ")[2].to_s
		puts name_
		tokens_ = msg.message.split(" ")[3..-1]
		puts tokens_.to_s
		text_ = ""
		tokens_.each { |token_| text_.concat("#{token_} ") }
		text_ = text_[0..-2].to_s
		puts text_

		puts names.to_s
		quotes_.push("#{text_} - #{name_}")
		if !names.include? name_
			names.push(name_)
		end
		puts names.to_s
		quotes[name_] ||= []
		quotes[name_] << text_

		bot.privmsg(msg.channel, "added: #{text_} - #{name_}")
	when /^\.quote --save$/ then
		save(names, quotes)
	when /^\.quote --list (\S+)$/ then
		case msg.message.split(" ")[2]
		when /^names$/ then
			match_ = ""
			names.each { |name_| match_.concat("#{name_} ")}
			bot.privmsg(msg.channel, match_)
		end
	end
end
#-------~-----~--~------~---~-------~----~------------~---~-----

#-------~-----~--~------~---~-------~----~------------~---~-----
# setup
#-------~-----~--~------~---~-------~----~------------~---~-----
bot.setup(use_ssl, use_pass, pass, nickserv_pass, channels)
bot.start!
#-------~-----~--~------~---~-------~----~------------~---~-----