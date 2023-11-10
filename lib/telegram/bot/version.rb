module Telegram
  module Bot
    VERSION = '0.16.0'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
