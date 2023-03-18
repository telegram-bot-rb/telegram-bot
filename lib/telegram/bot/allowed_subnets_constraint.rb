require 'ipaddr'

module Telegram
  module Bot
    # Restricts allowed IP addresses
    # @see https://core.telegram.org/bots/webhooks#the-short-version
    class AllowedSubnetsConstraint
      ALLOWED_SUBNETS = %w[149.154.160.0/20 91.108.4.0/22]

      def initialize(production_mode: !Rails.env.test?)
        @allowed_subnets =
          if production_mode
            ALLOWED_SUBNETS.map { |addr| IPAddr.new(addr) }
          else
            [IPAddr.new('0.0.0.0/0')]
          end
      end

      def matches?(request)
        @allowed_subnets.any? { |net| net.include?(request.remote_ip) }
      end
    end
  end
end
