module Telegram
  module Bot
    VERSION = '0.9.0.alpha1'.freeze

    def self.gem_version
      Gem::Version.new VERSION
    end
  end
end
