require 'rack/session/abstract/id'
require 'active_support/cache'

module Telegram
  module Bot
    class UpdatesController
      # Add functionality to store data between requests.
      module Session
        extend ActiveSupport::Concern

        def process_action(*)
          super
        ensure
          session.commit
        end

        protected

        def session
          @_session ||= SessionHash.new(self.class.session_store, session_key)
        end

        def session_key
          "#{bot.username}:#{from ? "from:#{from['id']}" : "chat:#{chat['id']}"}"
        end

        # Rack::Session::Abstract::SessionHash is taken to provide lazy loading.
        # All methods that access store are overriden to support
        # ActiveSupport::Cache::Store stores.
        class SessionHash < Rack::Session::Abstract::SessionHash
          attr_reader :id

          def initialize(store, id)
            @store = store
            @id = id
          end

          def destroy
            clear
            @store.delete(id)
          end

          def exists?
            return @exists if defined?(@exists)
            @data = {}
            @exists = @store.exist? id
          end

          def load!
            session = @store.read(id)
            @data = session ? stringify_keys(session) : {}
            @loaded = true
          end

          def commit
            return unless loaded?
            data = to_hash.delete_if { |_, v| v.nil? }
            @store.write(id, data)
          end
        end

        class TestSessionHash < SessionHash
          def initialize
            @data = {}
            @loaded = true
            @exists = true
          end

          alias_method :destroy, :clear
          alias_method :load!, :id
          alias_method :commit, :id
        end

        module ConfigMethods
          delegate :session_store, to: :config

          def session_store=(store)
            config.session_store = ActiveSupport::Cache.lookup_store(store)
          end
        end
      end
    end
  end
end
