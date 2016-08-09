module Telegram
  module Bot
    class Botan
      # Helpers for botan.io metrics.
      module ClientHelpers
        attr_reader :botan

        def initialize(*, botan: nil, **)
          super
          @botan = Botan.wrap(botan) if botan
        end
      end
    end
  end
end
