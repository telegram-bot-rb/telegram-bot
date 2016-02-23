require 'telegram/bot/routes_helper'

module Telegram
  module Bot
    class Railtie < Rails::Railtie
      config.telegram_updates_controller = ActiveSupport::OrderedOptions.new

      rake_tasks do
        load 'tasks/telegram-bot.rake'
      end

      config.before_initialize do
        ::ActionDispatch::Routing::Mapper.send(:include, RoutesHelper)
      end

      initializer 'telegram.bot.updates_controller.set_config' do |app|
        options = app.config.telegram_updates_controller

        ActiveSupport.on_load('telegram.bot.updates_controller') do
          self.logger = options.logger || Rails.logger
        end
      end

      initializer 'telegram.bot.updates_controller.add_ar_runtime' do
        ActiveSupport.on_load('telegram.bot.updates_controller') do
          if defined?(ActiveRecord::Railties::ControllerRuntime)
            include ActiveRecord::Railties::ControllerRuntime
          end
        end
      end
    end
  end
end
