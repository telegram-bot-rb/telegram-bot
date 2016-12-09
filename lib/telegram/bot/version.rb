module Telegram
  module Bot
    VERSION = '0.10.1'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
