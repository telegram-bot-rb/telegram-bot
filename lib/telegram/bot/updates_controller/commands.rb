module Telegram
  module Bot
    class UpdatesController
      #  Support for parsing commands
      module Commands
        CMD_REGEX = %r{\A/([a-z\d_]{,31})(@(\S+))?(\s|$)}i

        class << self
          # Fetches command from text message. All subsequent words are returned
          # as arguments.
          # If command has mention (eg. `/test@SomeBot`), it returns commands only
          # for specified username. Set `username` to `true` to accept
          # any commands.
          def command_from_text(text, username = nil)
            return unless text
            match = text.match(CMD_REGEX)
            return unless match
            mention = match[3]
            [match[1], text.split.drop(1)] if username == true || !mention || mention == username
          end
        end

        # Override it to filter or transform commands.
        # Default implementation is to downcase and add `!` suffix.
        def action_for_command(cmd)
          "#{cmd.downcase}!"
        end

        # If payload is a message with command, then returned action is an
        # action for this command.
        # Separate method, so it can be easily overriden (ex. MessageContext).
        #
        # This is not used for edited messages/posts. It process them as basic updates.
        def action_for_message
          cmd, args = Commands.command_from_text(payload['text'], bot_username)
          return unless cmd
          [[action_for_command(cmd), type: :command, command: cmd], args]
        end

        alias_method :action_for_channel_post, :action_for_message
      end
    end
  end
end
