require 'rack/session/abstract/id'
require 'active_support/cache'

module Telegram
  module Bot
    class UpdatesController
      # Add functionality to store data between requests.
      module Session
        extend ActiveSupport::Concern

        module ClassMethods
          # Builds session with given key and optional store (default to session_store).
          # This way it's easier to define multiple custom sessions,
          # ex. one for group chat and one for user.
          def build_session(key, store = session_store)
            raise 'session_store is not configured' unless store
            key ? SessionHash.new(store, key) : NullSessionHash.new
          end
        end

        def process_action(*)
          super
        ensure
          session.commit if @_session
        end

        protected

        def session
          @_session ||= self.class.build_session(session_key)
        end

        def session_key
          subject = from || chat
          "#{bot.username}:#{subject['id']}" if subject
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

        class NullSessionHash < Session::SessionHash
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

          def use_session!
            include Session
          end
        end
      end
    end
  end
end
