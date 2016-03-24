# Telegram::Bot

[![Gem Version](https://badge.fury.io/rb/telegram-bot.svg)](http://badge.fury.io/rb/telegram-bot)
[![Code Climate](https://codeclimate.com/github/telegram-bot-rb/telegram-bot/badges/gpa.svg)](https://codeclimate.com/github/telegram-bot-rb/telegram-bot)
[![Build Status](https://travis-ci.org/telegram-bot-rb/telegram-bot.svg)](https://travis-ci.org/telegram-bot-rb/telegram-bot)

Tools for developing bot for Telegram. Best used with Rails, but can be be used in
standalone app. Supposed to be used in webhook-mode in production, and poller-mode
in development, but you can use poller in production if you want.

Package contains:

- Ligthweight client for bot API (with fast and thread-safe
  [httpclient](https://github.com/nahi/httpclient) under the hood).
- Controller with message parser. Allows to write separate methods for each command.
- Middleware and routes helpers for production env.
- Poller with automatic source-reloader for development env.
- Rake tasks to update webhook urls.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'telegram-bot'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install telegram-bot

## Usage

### Configuration

Add `telegram` section into `secrets.yml`:

```yml
telegram:
  bots:
    # just set the token
    chat: TOKEN_1
    # or add username to support commands with mentions (/help@ChatBot)
    auction:
      token: TOKEN_2
      username: ChatBot

  # Single bot can be specified like this
  bot: TOKEN
  # or
  bot:
    token: TOKEN
    username: SomeBot
```

### Client

From now clients will be accessible with `Telegram.bots[:chat]` or `Telegram.bots[:auction]`.
Single bot can be accessed with `Telegram.bot` or `Telegram.bots[:default]`.

You can create clients manually with `Telegram::Bot::Client.new(token, username)`.
Username is optional and used only to parse commands with mentions.

There is `request(path_suffix, body)` method to perform any query.
And there are also shortcuts for available queries in underscored style
(`answer_inline_query` instead of `answerInlineQuery`).
All this methods just post given params to specific URL.

```ruby
bot.request(:getMe) or bot.get_me
bot.request(:getupdates, offset: 1) or bot.get_updates(offset: 1)
bot.send_message chat_id: chat_id, text: 'Test'
```

By default client will return parsed json responses. You can enable
response typecasting to virtus models using `telegram-bot-types` gem:
```ruby
# Add to your gemfile:
gem 'telegram-bot-types', '~> x.x.x'
# Enable typecasting:
Telegram::Bot::Client.typed_response!
# or for single instance:
bot.extend Telegram::Bot::Client::TypedResponse

bot.get_me.class # => Telegram::Bot::Types::User
```

Any API request error will raise `Telegram::Bot::Error` with description in its message.
Special `Telegram::Bot::StaleChat` is raised when bot can't post messages to the chat anymore.

### Controller

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  # use callbacks like in any other controllers
  around_action :with_locale

  # Every update can have one of: message, inline_query & chosen_inline_result.
  # Define method with same name to respond to this updates.
  def message(message)
    # message can be also accessed via instance method
    message == self.payload # true
    # store_message(message['text'])
  end

  # Define public methods to respond to commands.
  # Command arguments will be parsed and passed to the method.
  # Be sure to use splat args and default values to not get errors when
  # someone passed more or less arguments in the message.
  #
  # For some commands like /message or /123 method names should start with
  # `on_` to avoid conflicts.
  def start(data = nil, *)
    # do_smth_with(data)

    # There are `chat` & `from` shortcut methods.
    response = from ? "Hello #{from['username']}!" : 'Hi there!'
    # There is `reply_with` helper to set basic fields
    # like `reply_to_message` & `chat_id`.
    reply_with :message, text: response
  end

  private

  def with_locale(&block)
    I18n.with_locale(locale_for_update, &block)
  end

  def locale_for_update
    if from
      # locale for user
    elsif chat
      # locale for chat
    end
  end
end
```

You can enable typecasting of `update` with `telegram-bot-types` by including
`Telegram::Bot::UpdatesPoller::TypedUpdate`:

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::TypedUpdate

  def message(message)
    message.class # => Telegram::Bot::Types::Message
  end
end
```

There is support for sessions using `ActiveSupport::Cache` stores.

```ruby
# configure store in env files:
config.telegram_updates_controller.session_store = :redis_store, {expires_in: 1.month}

class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::Session
  # or just shortcut:
  use_session!

  # You can override global config
  self.session_store = :file_store

  def write(text = nil, *)
    session[:text] = text
  end

  def read
    reply_with :message, text: session[:text]
  end

  private
  # By default it uses bot's username and user's id as a session key.
  # Chat's id is used only when `from` field is empty.
  # Override `session_key` method to change this behavior.
  def session_key
    # In this case session will persist for user only in specific chat:
    "#{bot.username}:#{chat['id']}:#{from['id']}"
  end
end
```

It's usual to support chain of messages like BotFather: after receiving command
it asks you for additional argument. There is `MessageContext` for this:

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def rename(*)
    # set context for the next message
    save_context :rename
    reply_with :message, text: 'What name do you like?'
  end

  # register context handlers to handle this context
  context_handler :rename do |message|
    update_name message[:text]
    reply_with :message, text: 'Renamed!'
  end

  # You can do it in other way:
  def rename(name = nil, *)
    if name
      update_name name
      reply_with :message, text: 'Renamed!'
    else
      save_context :rename
      reply_with :message, text: 'What name do you like?'
    end
  end

  # This will call #rename like if it is called with message '/rename %text%'
  context_handler :rename

  # If you have a lot of such methods you can use
  context_to_action!
  # It'll use context value as action name for all contexts which miss handlers.
end
```

To process update run:

```ruby
ControllerClass.dispatch(bot, update)
```

There is also ability to run action without update:

```ruby
# Most likely you'll want to pass :from and :chat
controller = ControllerClass.new(bot, from: telegram_user, chat: telegram_chat)
controller.process(:help, *args)
```

### Routes

Use `telegram_webhooks` helper to add routes. It will create routes for bots
at "telegram/#{bot.token}" path.

```ruby
# Create routes for all Telegram.bots to use same controller:
telegram_webhooks TelegramController

# Or pass custom bots usin any of supported config options:
telegram_webhooks TelegramController,
                 bot,
                 {token: token, username: username},
                 other_bot_token

# Use different controllers for each bot:
telegram_webhooks bot => TelegramChatController,
                  other_bot => TelegramAuctionController

# telegram_webhooks creates named routes.
# Route name depends on `Telegram.bots`.
# When there is single bot it will use 'telegram_webhook'.
# When there are it will use bot's key in the `Telegram.bots` as prefix
# (eg. `chat_telegram_webhook`).
# You can override this options or specify others:
telegram_webhooks TelegramController, as: :my_webhook
telegram_webhooks bot => [TelegramChatController, as: :chat_webhook],
                  other_bot => [TelegramAuctionController,
```

For Rack applications you can also use `Telegram::Bot::Middleware` or just
call `.dispatch(bot, update)` on controller.

### Development & Debugging

Use `rake telegram:bot:poller` to run poller. It'll automatically load
changes without restart in development env. Optionally specify bot to run poller for
with `BOT` envvar (`BOT=chat`).

This task will not work if you don't use `telegram_webhooks`.
You can run poller manually with
`Telegram::Bot::UpdatesPoller.start(bot, controller_class)`.

### Testing

There is `Telegram::Bot::ClientStub` class to stub client for tests.
Instead of performing API requests it stores them in `requests` hash.

To stub all possible clients use `Telegram::Bot::ClientStub.stub_all!` before
initializing clients. Most likely you'll want something like this:

```ruby
RSpec.configure do |config|
  # ...
  Telegram.reset_bots
  Telegram::Bot::ClientStub.stub_all!
  config.after { Telegram.bot.reset }
  # ...
end
```

There are also some helpers for controller tests.
Check out `telegram/bot/updates_controller/rspec_helpers` and
`telegram/bot/updates_controller/testing`.

### Deploying

Use `rake telegram:bot:set_webhook` to update webhook url for all configured bots.
Certificate can be specified with `CERT=path/to/cert`.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/telegram-bot-rb/telegram-bot.
