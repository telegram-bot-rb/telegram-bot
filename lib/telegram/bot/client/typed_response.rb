module Telegram
  module Bot
    class Client
      # Actions with type-casted results. Install `telegram-bot-types` gem first.
      module TypedResponse
        {
          getFile:              :File,
          getMe:                :User,
          getUpdates:           [:Update],
          getUserProfilePhotos: :UserProfilePhotos,

          forwardMessage:       :Message,
          sendAudio:            :Message,
          sendDocument:         :Message,
          sendLocation:         :Message,
          sendMessage:          :Message,
          sendPhoto:            :Message,
          sendSticker:          :Message,
          sendVideo:            :Message,
          sendVoice:            :Message,
        }.each do |method, type|
          next unless type
          if type.is_a?(Array)
            type_class = Types.const_get(type.first)
            define_method(method.to_s.underscore) do |*args|
              request(method, *args)['result'].map { |x| type_class.new(x) }
            end
          else
            type_class = Types.const_get(type)
            define_method(method.to_s.underscore) do |*args|
              type_class.new request(method, *args)['result']
            end
          end
        end
      end
    end
  end
end
