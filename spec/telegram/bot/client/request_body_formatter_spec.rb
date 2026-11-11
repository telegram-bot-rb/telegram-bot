# frozen_string_literal: true

RSpec.describe Telegram::Bot::Client::RequestBodyFormatter do
  describe '.format' do
    subject { described_class.format(input, action) }
    let(:action) { :sendMessage }

    context 'when plain hash is given' do
      let(:input) { {a: 1, b: '2', c: nil} }
      it { should eq input }
    end

    context 'when nested hash is given' do
      let(:input) { {a: 1, b: '2', c: [1, 2], d: {a: 1}, e: {b: []}} }

      it 'encodes nested hashes to json' do
        expected = input.dup
        %i[c d e].each { |x| expected[x] = expected[x].to_json }
        should eq expected
      end
    end

    context 'when file is given at the top-level' do
      let(:input) { {chat_id: 1, photo: File.new(__FILE__)} }
      it('leaves it for http client') { should eq input }
    end

    context 'when nested value has custom #to_json' do
      let(:input) { {reply_markup: custom_hash.new.merge!(a: 1)} }
      let(:custom_hash) do
        Class.new(Hash) do
          def to_json(*)
            '"custom"'
          end
        end
      end

      it 'is used when there are no files inside' do
        should eq(reply_markup: '"custom"')
      end
    end

    # There is no list of actions with nested files: every action is handled.
    context 'when files are nested in params' do
      let(:file_1) { File.new(__FILE__) }
      let(:file_2) { File.new(__FILE__) }
      let(:file_3) { File.new(__FILE__) }

      context 'with sendPaidMedia action' do
        let(:action) { :sendPaidMedia }
        let(:input) do
          {
            star_count: 1,
            media: [
              {type: 'photo', media: file_1},
              {type: 'video', media: file_2, cover: file_3},
            ],
          }
        end

        it 'extracts files to the top-level' do
          should eq(
            star_count: 1,
            media: [
              {type: 'photo', media: 'attach://_file0'},
              {type: 'video', media: 'attach://_file1', cover: 'attach://_file2'},
            ].to_json,
            '_file0' => file_1,
            '_file1' => file_2,
            '_file2' => file_3,
          )
        end
      end

      context 'with createNewStickerSet action' do
        let(:action) { :createNewStickerSet }
        let(:input) do
          {name: 'set', stickers: [{sticker: file_1, format: 'static', emoji_list: ['👍']}]}
        end

        it 'extracts files to the top-level' do
          should eq(
            name: 'set',
            stickers: [{sticker: 'attach://_file0', format: 'static', emoji_list: ['👍']}].to_json,
            '_file0' => file_1,
          )
        end
      end

      context 'in multiple params' do
        let(:action) { :setMyProfilePhoto }
        let(:input) { {photo: {type: 'static', photo: file_1}, other: [{deep: [file_2]}], x: 789} }

        it 'numbers them through all params' do
          should eq(
            photo: {type: 'static', photo: 'attach://_file0'}.to_json,
            other: [{deep: ['attach://_file1']}].to_json,
            x: 789,
            '_file0' => file_1,
            '_file1' => file_2,
          )
        end
      end
    end

    context 'with sendMediaGroup action' do
      let(:action) { :sendMediaGroup }
      let(:input) { {media: [{a: file_1}, {'b' => file_2, c: 123}, {d: 456}], x: 789} }
      let(:file_1) { File.new(__FILE__) }
      let(:file_2) { File.new(__FILE__) }

      it 'extracts files to the top-level' do
        should eq(
          media: [
            {a: 'attach://_file0'},
            {b: 'attach://_file1', c: 123},
            {d: 456},
          ].to_json,
          x: 789,
          '_file0' => file_1,
          '_file1' => file_2,
        )
      end

      context 'and input has string keys' do
        let(:input) { super().stringify_keys }
        it 'extracts files to the top-level' do
          should eq(
            'media' => [
              {a: 'attach://_file0'},
              {b: 'attach://_file1', c: 123},
              {d: 456},
            ].to_json,
            'x' => 789,
            '_file0' => file_1,
            '_file1' => file_2,
          )
        end
      end

      context 'without media' do
        let(:input) { {a: 1, b: '2', c: nil} }
        it { should eq input }
      end
    end

    context 'with editMessageMedia action' do
      let(:action) { :editMessageMedia }
      let(:input) { {media: {a: file, b: 123}, x: 789} }
      let(:file) { File.new(__FILE__) }

      it 'extracts files to the top-level' do
        should eq(
          media: {a: 'attach://_file0', b: 123}.to_json,
          x: 789,
          '_file0' => file,
        )
      end

      context 'and input has string keys' do
        let(:input) { super().stringify_keys }
        it 'extracts files to the top-level' do
          should eq(
            'media' => {a: 'attach://_file0', b: 123}.to_json,
            'x' => 789,
            '_file0' => file,
          )
        end
      end

      context 'without media' do
        let(:input) { {a: 1, b: '2', c: nil} }
        it { should eq input }
      end
    end

    context 'with postStory action' do
      let(:action) { :postStory }
      let(:input) { {content: {a: file, b: 123}, x: 789} }
      let(:file) { File.new(__FILE__) }

      it 'extracts files to the top-level' do
        should eq(
          content: {a: 'attach://_file0', b: 123}.to_json,
          x: 789,
          '_file0' => file,
        )
      end

      context 'and input has string keys' do
        let(:input) { super().stringify_keys }
        it 'extracts files to the top-level' do
          should eq(
            'content' => {a: 'attach://_file0', b: 123}.to_json,
            'x' => 789,
            '_file0' => file,
          )
        end
      end

      context 'without content' do
        let(:input) { {a: 1, b: '2', c: nil} }
        it { should eq input }
      end
    end

    context 'with sendRichMessage action' do
      let(:action) { :sendRichMessage }
      let(:file_1) { File.new(__FILE__) }
      let(:file_2) { File.new(__FILE__) }
      let(:input) do
        {
          chat_id: 1,
          rich_message: {
            blocks: [
              {type: 'photo', photo: {type: 'photo', media: file_1}},
              {type: 'details', summary: 'More', blocks: [
                {type: 'video', video: {type: 'video', media: file_2}},
                {type: 'paragraph', text: 'Hi'},
              ]},
            ],
          },
        }
      end

      it 'extracts deeply nested files to the top-level' do
        should eq(
          chat_id: 1,
          rich_message: {
            blocks: [
              {type: 'photo', photo: {type: 'photo', media: 'attach://_file0'}},
              {type: 'details', summary: 'More', blocks: [
                {type: 'video', video: {type: 'video', media: 'attach://_file1'}},
                {type: 'paragraph', text: 'Hi'},
              ]},
            ],
          }.to_json,
          '_file0' => file_1,
          '_file1' => file_2,
        )
      end

      context 'without files' do
        let(:input) do
          {chat_id: 1, rich_message: {blocks: [{type: 'paragraph', text: 'Hi'}]}}
        end

        it 'json-encodes the rich message unchanged' do
          should eq(
            chat_id: 1,
            rich_message: {blocks: [{type: 'paragraph', text: 'Hi'}]}.to_json,
          )
        end
      end

      context 'without rich_message' do
        let(:input) { {a: 1, b: '2', c: nil} }
        it { should eq input }
      end
    end
  end
end
