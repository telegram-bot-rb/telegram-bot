# frozen_string_literal: true

require 'json'

module Telegram
  module Bot
    class Client
      # Encodes nested hashes and arrays as json and extracts File objects from them
      # to the top level. Top-level File objects are handled by httpclient.
      # More details: https://core.telegram.org/bots/api#sending-files
      #
      # Files are extracted from nested params of any method: the list of methods
      # that accept them (`media` in sendMediaGroup, `stickers` in createNewStickerSet,
      # `photo` in setMyProfilePhoto, blocks of `rich_message`, etc.)
      # grows with almost every Bot API update.
      module RequestBodyFormatter
        extend self

        def format(body, _action)
          body = body.dup
          files = {}
          body.each do |key, val|
            next unless val.is_a?(Hash) || val.is_a?(Array)
            files_count = files.size
            extracted = extract_files(val, files)
            # Original object is encoded when there are no files in it,
            # because it can have custom #to_json.
            body[key] = (files.size == files_count ? val : extracted).to_json
          end
          files.empty? ? body : body.merge!(files)
        end

        private

        # Replaces File objects with `attach` URIs, descending into nested hashes
        # and arrays. File objects are added into `files` hash.
        def extract_files(value, files)
          case value
          when File
            arg_name = "_file#{files.size}"
            files[arg_name] = value
            "attach://#{arg_name}"
          when Hash
            value.transform_values { |x| extract_files(x, files) }
          when Array
            value.map { |x| extract_files(x, files) }
          else
            value
          end
        end
      end
    end
  end
end
