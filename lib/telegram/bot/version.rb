module Telegram
  module Bot
    VERSION = '0.15.6'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
