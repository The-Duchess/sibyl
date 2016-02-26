load 'sibyl_conf.rb'

require 'rirc'

config = ConfigClass.new

#-------~-----~--~------~---~-------~----~------------~---~-----
#setup
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
#puts admins.to_s
bot.set_admins(admins)

#puts "Loading Plugins"
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
bot.on :message do |msg|
      commands.check_cmds(bot, msg, plug)

      responses = plug.check_all(msg, bot.admins, bot.backlog)
      responses.each { |a| bot.say(a) }
end

bot.on :message do |msg|
	case msg.message
	when /[Hh]ello. #{nick}/ then
		bot.privmsg(msg.channel, "Hello: #{msg.nick}")
	end
end

bot.stop! /^\.leave$/ do |msg|
    bot.channels.each do |channel|
    	bot.notice(channel, "leaving")
    end
end
#-------~-----~--~------~---~-------~----~------------~---~-----

#-------~-----~--~------~---~-------~----~------------~---~-----
# setup
#-------~-----~--~------~---~-------~----~------------~---~-----
bot.setup(use_ssl, use_pass, pass, nickserv_pass, channels)
bot.start!
#-------~-----~--~------~---~-------~----~------------~---~-----