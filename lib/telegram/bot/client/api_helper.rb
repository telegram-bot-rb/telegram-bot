require 'active_support/core_ext/string/inflections'

module Telegram
  module Bot
    class Client
      module ApiHelper
        METHODS_LIST_FILE = File.expand_path('../api_methods.txt', __FILE__)

        class << self
          def methods_list(file = METHODS_LIST_FILE)
            File.read(file).lines.
              map(&:strip).
              reject { |x| x.empty? || x.start_with?('#') }
          end

          # Defines method with underscored name to post to specific endpoint:
          #
          #   define_method :getMe
          #   # defines #get_me
          def define_helpers(*list)
            list.map(&:to_s).each do |method|
              define_method(method.underscore) { |*args| request(method, *args) }
            end
          end
        end

        define_helpers(*methods_list)
      end
    end
  end
end
