# frozen_string_literal: true

module Telegram
  module Bot
    module Tasks
      extend self

      def set_webhook
        routes = Rails.application.routes.url_helpers
        cert_file = ENV['CERT']
        cert = File.open(cert_file) if cert_file
        each_bot do |key, bot|
          route_name = RoutesHelper.route_name_for_bot(bot)
          url = routes.send("#{route_name}_url")
          say("Setting webhook for #{key}...")
          bot.set_webhook(
            url: url,
            certificate: cert,
            ip_address: ENV['IP_ADDRESS'],
            drop_pending_updates: drop_pending_updates,
          )
        end
      end

      def delete_webhook
        each_bot do |key, bot|
          say("Deleting webhook for #{key}...")
          bot.delete_webhook(drop_pending_updates: drop_pending_updates)
        end
      end

      def log_out
        each_bot do |key, bot|
          say("Logging out #{key}...")
          bot.log_out
        end
      end

      def close
        each_bot do |key, bot|
          say("Closing #{key}...")
          bot.close
        end
      end

      private

      def say(text)
        puts(text) unless Rails.env.test? # rubocop:disable Rails/Output
      end

      def each_bot(&block)
        id = ENV['BOT'].try!(:to_sym)
        bots = id ? {id => Client.by_id(id)} : Telegram.bots
        bots.each { |key, bot| bot.async(false) { block[key, bot] } }
      end

      def drop_pending_updates
        ENV['DROP_PENDING_UPDATES'].try!(:downcase) == 'true'
      end
    end
  end
end
