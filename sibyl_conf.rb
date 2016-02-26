module ConfigsModule

	def initialize
		@config =
		{
			:network   => "irc.freenode.net",     # network url
			:port      => 6697,                   # port
			:SSL       => true,                   # connect with ssl
			:pass      => "",                     # network pass
			:nick      => "sibyl",                # nick
			:username  => "sibyl",                # username
			:realname  => "sibyl",                # realname
			:usepass   => false,                  # use network pass
			:nickpass  => "",                     # nickpass, if not used leave empty
			:admins    => ["YOURNICK", "OTHERS"], # users that will be added to the admins
			:ignore    => [],                     # ignore list
			:plugins   => [],                     # plugins to load at startup
			:plugindir => "./",                   # dir for plugins
			:channels  => ["#YOURCHANNEL"]        # channels to join
		}
	end

	def acquire
		return @config
	end

end

class ConfigClass
	include ConfigsModule
end