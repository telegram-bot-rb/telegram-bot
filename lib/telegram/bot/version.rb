module Telegram
  class Bot
    VERSION = '0.3.0'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
