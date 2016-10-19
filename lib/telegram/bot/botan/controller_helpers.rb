module Telegram
  module Bot
    class Botan
      # Helpers for botan.io metrics.
      module ControllerHelpers
        class MissingFrom < Error; end

        protected

        def botan
          @botan ||= bot.try!(:botan)
        end

        # Track custom event for user taken from `from` field:
        #
        #   botan_track :my_event, {data: :val}
        #
        def botan_track(event, data = {})
          raise MissingFrom, 'Can not track without user' unless from
          botan.try! { |x| x.track(event, from['id'], data) }
        end

        # Track current action and payload for current user. Best used with `before_action`:
        #
        #   before_action :botan_track_action
        #
        def botan_track_action
          botan_track(action_name, payload)
        end
      end
    end
  end
end
