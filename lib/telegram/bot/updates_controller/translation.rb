module Telegram
  module Bot
    class UpdatesController
      # Provides helpers similar to AbstractController::Translation
      # but by default uses `action_name_i18n_key` in lazy translation keys
      # which strips `!` from action names by default. This makes translating
      # strings for commands more convenient.
      #
      # To disable this behaviour use `alias_method :action_name_i18n_key, :action_name`.
      module Translation
        extend ActiveSupport::Concern

        module ClassMethods
          # Class-level helper for lazy translations.
          def translate(key, options = {})
            key = "#{controller_path.tr('/', '.')}#{key}" if key.to_s.start_with?('.')
            I18n.translate(key, options)
          end
          alias :t :translate
        end

        # See toplevel description.
        def translate(key, options = {})
          if key.to_s.start_with?('.')
            path = controller_path.tr('/', '.')
            defaults = [:"#{path}#{key}"]
            defaults << options[:default] if options[:default]
            options[:default] = defaults.flatten
            key = "#{path}.#{action_name_i18n_key}#{key}"
          end
          I18n.translate(key, options)
        end
        alias :t :translate

        # Strips trailing `!` from action_name.
        def action_name_i18n_key
          action_name.chomp('!')
        end

        def localize(*args)
          I18n.localize(*args)
        end
        alias :l :localize
      end
    end
  end
end
