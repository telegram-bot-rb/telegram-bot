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
  end
end
