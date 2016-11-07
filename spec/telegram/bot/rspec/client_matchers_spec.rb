RSpec.describe Telegram::Bot::RSpec::ClientMatchers do
  let(:bot) { Telegram::Bot::ClientStub.new('TestBot') }
  let(:other_bot) { Telegram::Bot::ClientStub.new('OtherTestBot') }

  include described_class

  describe '#make_telegram_request' do
    context 'without args' do
      it 'works for matching' do
        block = ->(*) { bot.send_message(text: 'test') }
        expect(&block).to make_telegram_request(bot, :sendMessage)
        expect { 3.times(&block) }.to make_telegram_request(bot, :sendMessage).exactly(3).times
        expect { 3.times(&block) }.to make_telegram_request(bot, :sendMessage).at_least(2).times
        expect { 3.times(&block) }.to make_telegram_request(bot, :sendMessage).at_most(4).times
      end

      it 'works for not-matching' do
        block = ->(*) { bot.get_me }
        expect {}.to_not make_telegram_request(bot, :getMe)
        expect { other_bot.get_me }.to_not make_telegram_request(bot, :getMe)
        expect { 3.times(&block) }.to_not make_telegram_request(bot, :getMe)
        expect { 3.times(&block) }.to_not make_telegram_request(bot, :getMe).exactly(2).times
        expect { 3.times(&block) }.to_not make_telegram_request(bot, :getMe).exactly(4).times
        expect { 3.times(&block) }.to_not make_telegram_request(bot, :getMe).at_least(4).times
        expect { 3.times(&block) }.to_not make_telegram_request(bot, :getMe).at_most(2).times
      end
    end

    context 'with args' do
      it 'works for exact matching' do
        args = {text: 'test', parseMode: :Markdown}
        block = ->(*) { bot.send_message(args) }
        expect(&block).to make_telegram_request(bot, :sendMessage).with(args)
        expect(&block).to_not make_telegram_request(bot, :sendMessage).with(args.except(:text))
        expect { 3.times(&block) }.to make_telegram_request(bot, :sendMessage).
          with(args).exactly(3).times
      end

      it 'works for block matchers' do
        args = {text: 'test', parseMode: :Markdown}
        block = ->(*) { bot.send_message(args) }
        expect(&block).to make_telegram_request(bot, :sendMessage).
          with { |actual| expect(actual).to eq(args) }
        # It ignores block's result! Custom expectations must be used inside block.
        expect(&block).to make_telegram_request(bot, :sendMessage).
          with { |actual| actual == {} }
        expect do
          expect(&block).to_not make_telegram_request(bot, :sendMessage).
            with { |actual| expect(actual).to eq({}) }
        end.to raise_error RSpec::Expectations::ExpectationNotMetError
        n = -1
        expect { 3.times { |i| bot.send_message text: i } }.
          to make_telegram_request(bot, :sendMessage).exactly(3).times.
            with { |actual| expect(actual).to eq(text: n += 1) }
      end

      it 'works for RSpec::Mocks matchers' do
        args = {text: 'test', parseMode: :Markdown}
        block = ->(*) { bot.send_message(args) }
        expect(&block).to make_telegram_request(bot, :sendMessage).with(hash_including(args))
        expect(&block).to make_telegram_request(bot, :sendMessage).with(
          text: a_string_matching(/est$/),
          parseMode: :Markdown,
        )
      end
    end
  end

  describe '#send_telegram_message' do
    let(:args) { {text: 'test', parseMode: :Markdown} }
    let(:block) { ->(*) { bot.send_message(args) } }

    it 'works for matching' do
      expect(&block).to send_telegram_message(bot, 'test')
      expect(&block).to send_telegram_message(bot, /^tes/)
      expect(&block).to send_telegram_message(bot, 'test', parseMode: :Markdown)
      expect(&block).to send_telegram_message(bot, a_string_including('es'))
    end

    it 'works for not-matching' do
      expect(&block).to_not send_telegram_message(bot, 'test!')
      expect(&block).to_not send_telegram_message(bot, /tes$/)
      expect(&block).to_not send_telegram_message(bot, 'test', parseMode: :HTML)
      expect(&block).to_not send_telegram_message(bot, a_string_including('smth'))
    end
  end
end
