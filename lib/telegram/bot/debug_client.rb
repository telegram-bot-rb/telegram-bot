module Telegram
  module Bot
    module DebugClient
      def debug!(dev = STDOUT)
        if block_given?
          begin
            old_dev = client.debug_dev
            client.debug_dev = dev
            yield
          ensure
            client.debug_dev = old_dev
          end
        else
          client.debug_dev = dev
        end
      end

      def debug_off!
        client.debug_dev = nil
      end
    end
  end
end
