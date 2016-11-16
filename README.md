# Telegram::Bot

[![Gem Version](https://badge.fury.io/rb/telegram-bot.svg)](http://badge.fury.io/rb/telegram-bot)
[![Code Climate](https://codeclimate.com/github/telegram-bot-rb/telegram-bot/badges/gpa.svg)](https://codeclimate.com/github/telegram-bot-rb/telegram-bot)
[![Build Status](https://travis-ci.org/telegram-bot-rb/telegram-bot.svg)](https://travis-ci.org/telegram-bot-rb/telegram-bot)

Tools for developing bot for Telegram. Best used with Rails, but can be be used in
[standalone app](https://github.com/telegram-bot-rb/telegram-bot/wiki/Non-rails-application).
Supposed to be used in webhook-mode in production, and poller-mode
in development, but you can use poller in production if you want.

Package contains:

- Ligthweight client for bot API (with fast and thread-safe
  [httpclient](https://github.com/nahi/httpclient) under the hood).
- Controller with message parser. Allows to write separate methods for each command.
- Middleware and routes helpers for production env.
- Poller with automatic source-reloader for development env.
- Rake tasks to update webhook urls.
- __[Async mode](#async-mode)__ for Telegram and/or Botan API.
  Let the queue adapter handle network errors!

Here is sample [telegram_bot_app](https://github.com/telegram-bot-rb/telegram_bot_app)
with session, keyboards and inline queries.
Run it on your local machine in 1 minute!

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

  # Every update can have one of: message, inline_query, chosen_inline_result,
  # callback_query.
  # Define method with same name to respond to this updates.
  def message(message)
    # message can be also accessed via instance method
    message == self.payload # true
    # store_message(message['text'])
  end

  # This basic methods receives commonly used params:
  #
  #   message(payload)
  #   inline_query(query, offset)
  #   chosen_inline_result(result_id, query)
  #   callback_query(data)

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
    # For callback queries `chat` if taken from `message` when it's available.
    response = from ? "Hello #{from['username']}!" : 'Hi there!'
    # There is `respond_with` helper to set `chat_id` from received message:
    respond_with :message, text: response
    # `reply_with` also sets `reply_to_message_id`:
    reply_with :photo, photo: File.open('party.jpg')
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

#### Optional typecasting

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

#### Session

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
    respond_with :message, text: session[:text]
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

#### Message context

It's usual to support chain of messages like BotFather: after receiving command
it asks you for additional argument. There is `MessageContext` for this:

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext

  def rename(*)
    # set context for the next message
    save_context :rename
    respond_with :message, text: 'What name do you like?'
  end

  # register context handlers to handle this context
  context_handler :rename do |*words|
    update_name words[0]
    respond_with :message, text: 'Renamed!'
  end

  # You can do it in other way:
  def rename(name = nil, *)
    if name
      update_name name
      respond_with :message, text: 'Renamed!'
    else
      save_context :rename
      respond_with :message, text: 'What name do you like?'
    end
  end

  # This will call #rename like if it is called with message '/rename %text%'
  context_handler :rename

  # If you have a lot of such methods you can use
  context_to_action!
  # It'll use context value as action name for all contexts which miss handlers.
end
```

You can use `CallbackQueryContext` in the similar way to split `#callback_query` into
several specific methods. It doesn't require session support, and takes context from
data. If data has a prefix with colon like this `my_ctx:smth...` it'll call
`my_ctx_callback_query('smth...')` when there is such action method. Otherwise
it'll call `callback_query('my_ctx:smth...')` as usual.

#### Processesing updates

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
                  other_bot => TelegramAuctionController,
                  admin_chat: TelegramAdminChatController
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
# environments/test.rb
# Make sure to run it before defining routes or storing bot to some place in app!
Telegram.reset_bots
Telegram::Bot::ClientStub.stub_all!

# rails_helper.rb
RSpec.configure do |config|
  # ...
  config.after { Telegram.bot.reset }
  # ...
end
```

There are integration and controller contexts for RSpec and some built-in matchers:

```ruby
# spec/requests/telegram_webhooks_spec.rb
require 'telegram/bot/rspec/integration'

RSpec.describe TelegramWebhooksController, :telegram_bot do
  # for old rspec add:
  # include_context 'telegram/bot/integration'

  describe '#start' do
    subject { -> { dispatch_command :start } }
    it { should respond_with_message 'Hi there!' }
  end
end

# For controller specs use
require 'telegram/bot/updates_controller/rspec_helpers'
RSpec.describe TelegramWebhooksController, type: :telegram_bot_controller do
  # for old rspec add:
  # include_context 'telegram/bot/updates_controller'
end

# Matchers are available for custom specs:
include Telegram::Bot::RSpec::ClientMatchers

expect(&process_update).to send_telegram_message(bot, /msg regexp/, some: :option)
expect(&process_update).
  to make_telegram_request(bot, :sendMessage, hash_including(text: 'msg text'))
```

See sample app for more examples.

### Deploying

Use `rake telegram:bot:set_webhook` to update webhook url for all configured bots.
Certificate can be specified with `CERT=path/to/cert`.

### Botan.io metrics

Initialize with `bot = Telegram::Bot::Client.new(token, botan: 'botan token')`
or just add `botan` key in `secrets.yml`:

```yml
  telegram:
    bot:
      token: bot_token
      botan: botan_token
```

Access to Botan client with `bot.botan`.
Use `bot.botan.track(event, uid, payload)` to track events.

There are some helpers for controllers in `Telegram::Bot::Botan::ControllerHelpers`:

```ruby
class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::Botan::ControllerHelpers

  # This will track with event: action_name & data: payload
  before_action :botan_track_action

  def smth(*)
    # This will track event for current user only when botan is configured.
    botan_track :my_event, custom_data

    # or get access directly to botan client:
    botan.track(...)
  end
end
```

There is no stubbing for botan clients, so don't set botan token in tests.

### Async mode

There is built in support for async requests using ActiveJob. Without Rails
you can implement your own worker class to handle such requests. This allows:

- Process updates very fast, without waiting for telegram and botan responses.
- Handle and retry network and other errors with queue adapter.
- ???

Instead of performing request instantly client serializes it, pushes to queue,
and immediately return control back. The job is then fetched with a worker
and real API request is performed. And this all is absolutely transparent for the app.

To enable this mode add `async: true` to bot's and botan's config.
For more information and custom configuration check out
[docs](http://www.rubydoc.info/github/telegram-bot-rb/telegram-bot/master/Telegram/Bot/Async) or
[source](https://github.com/telegram-bot-rb/telegram-bot/blob/master/lib/telegram/bot/async.rb).

If you want async mode, but don't want to setup queue, know that Rails 5 are shipped
with Async adapter by default, and there is
[Sucker Punch](https://github.com/brandonhilkert/sucker_punch) for Rails 4.

Be aware of some limitations:

- Client will not return API response.
- Sending files is not available in async mode [now],
  because them can not be serialized.

To disable async mode for the block of code use `bot.async(false) { bot.send_photo }`.
Yes, it's threadsafe too.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Different Rails versions

To setup development for specific major Rails version use:

```
RAILS=5 bundle install
# or
RAILS=5 bundle update
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/telegram-bot-rb/telegram-bot.
