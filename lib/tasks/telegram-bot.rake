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
      Telegram::Bot::Tasks.set_webhook
    end

    desc 'Delete webhooks for all or specific BOT'
    task :delete_webhook do
      Telegram::Bot::Tasks.delete_webhook
    end

    desc 'Perform logOut command for all or specific BOT'
    task :log_out do
      Telegram::Bot::Tasks.log_out
    end

    desc 'Perform `close` command for all or specific BOT'
    task :close do
      Telegram::Bot::Tasks.close
    end
  end
end
