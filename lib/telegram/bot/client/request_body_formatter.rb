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
          if action.to_s == 'sendMediaGroup'
            body = extract_files_from_array!(body, :media)
          end
          body.each do |key, val|
            body[key] = val.to_json if val.is_a?(Hash) || val.is_a?(Array)
          end
        end

        private

        def extract_files_from_array!(body, field_name)
          field_name = [field_name.to_sym, field_name.to_s].find { |x| body.key?(x) }
          return body unless field_name && body[field_name].is_a?(Array)
          files = {}
          body[field_name] = body[field_name].map { |x| extract_files_from_hash(x, files) }
          body.merge!(files)
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
