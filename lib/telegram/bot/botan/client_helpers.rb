module Telegram
  module Bot
    class Botan
      # Helpers for botan.io metrics.
      module ClientHelpers
        attr_reader :botan

        def initialize(*, botan: nil, **options)
          super
          @botan = Botan.wrap(botan, id: id) if botan
        end
      end
    end
  end
end
