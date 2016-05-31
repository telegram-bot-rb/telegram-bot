namespace :telegram do
  namespace :bot do
    desc 'Run poller. It broadcasts Rails.logger to STDOUT in dev like `rails s` do. ' \
      'Use LOG_TO_STDOUT to enable/disable broadcasting.'
    task :poller do
      ENV['BOT_POLLER_MODE'] = 'true'
      Rake::Task['environment'].invoke
      if ENV.fetch('LOG_TO_STDOUT') { Rails.env.development? }.present?
        console = ActiveSupport::Logger.new(STDERR)
        Rails.logger.extend ActiveSupport::Logger.broadcast console
      end
      Telegram::Bot::UpdatesPoller.start(ENV['BOT'].try!(:to_sym) || :default)
    end

    desc 'Set webhook urls for all bots'
    task set_webhook: :environment do
      routes = Rails.application.routes.url_helpers
      cert_file = ENV['CERT']
      cert = File.open(cert_file) if cert_file
      Telegram.bots.each do |key, bot|
        route_name = Telegram::Bot::RoutesHelper.route_name_for_bot(bot)
        url = routes.send("#{route_name}_url")
        puts "Setting webhook for #{key}..."
        bot.set_webhook(url: url, certificate: cert)
      end
    end
  end
end
