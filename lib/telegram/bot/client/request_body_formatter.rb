# frozen_string_literal: true

require 'json'

module Telegram
  module Bot
    class Client
      # Encodes nested hashes and arrays as json and extract File objects from them
      # to the top level. Top-level File objects are handled by httpclient.
      # More details: https://core.telegram.org/bots/api#sending-files
      module RequestBodyFormatter
        extend self

        def format(body, action)
          body = body.dup
          case action.to_s
          when 'sendMediaGroup'
            extract_files_from_array!(body, :media)
          when 'editMessageMedia'
            replace_field(body, :media) do |value|
              files = {}
              extract_files_from_hash(value, files).tap { body.merge!(files) }
            end
          end
          body.each do |key, val|
            body[key] = val.to_json if val.is_a?(Hash) || val.is_a?(Array)
          end
        end

        private

        # Detects field by symbol or string name and replaces it with mapped value.
        def replace_field(hash, field_name)
          field_name = [field_name.to_sym, field_name.to_s].find { |x| hash.key?(x) }
          hash[field_name] = yield hash[field_name] if field_name
        end

        def extract_files_from_array!(hash, field_name)
          replace_field(hash, field_name) do |value|
            break value unless value.is_a?(Array)
            files = {}
            value.map { |x| extract_files_from_hash(x, files) }.
              tap { hash.merge!(files) }
          end
        end

        # Replace File objects with `attach` URIs. File objects are added into `files` hash.
        def extract_files_from_hash(hash, files)
          return hash unless hash.is_a?(Hash)
          hash.transform_values do |value|
            if value.is_a?(File)
              arg_name = "_file#{files.size}"
              files[arg_name] = value
              "attach://#{arg_name}"
            else
              value
            end
          end
        end
      end
    end
  end
end
