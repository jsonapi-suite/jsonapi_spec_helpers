require 'spec_helper'

describe JsonapiSpecHelpers do
  include JsonapiSpecHelpers
  attr_accessor :response

  let(:instance) { klass.new }

  let(:status) { 200 }
  let(:headers) { {} }
  let(:body) { JSON.generate(response_json) }

  let(:response_json) do
    {}
  end

  let(:raw_response) do
    double \
      status: status,
      headers: headers,
      body: body
  end

  let(:response) { ActionDispatch::TestResponse.from_response(raw_response) }

  def post_attributes
    @index = 0 if @index.nil?
    @index += 1

    {
      title: "post title #{@index}",
      description: "post description #{@index}"
    }
  end

  def basic_post_response
    {
      data: {
        type: 'posts',
        id: '1',
        attributes: post_attributes
      }
    }
  end

  def basic_posts_response
    {
      data: [
        { type: 'posts', id: '1', attributes: post_attributes },
        { type: 'posts', id: '2', attributes: post_attributes },
      ]
    }
  end

  def included_response
    {
      data: {
        type: 'posts',
        relationships: {
          comments: {
            data: [
              { type: 'comments', id: '456' },
              { type: 'comments', id: '567' },
            ]
          },
          author: {
            data: {
              type: 'authors',
              id: '789'
            }
          }
        }
      },
      included: [
        { type: 'comments', id: '456', attributes: { body: 'comment1' } },
        { type: 'comments', id: '567', attributes: { body: 'comment2' } },
        { type: 'authors',  id: '789', attributes: { name: 'Joe' } }
      ]
    }
  end

  after do
    JsonapiSpecHelpers::Payload.registry = {}
  end

  describe '#json' do
    let(:response_json) { { foo: 'bar' } }

    it 'parses response json' do
      expect(json).to eq({ 'foo' => 'bar' })
    end
  end

  describe '#json_item' do
    let(:response_json) { basic_post_response }

    it 'merges id/type/attributes' do
      expect(json_item).to eq({
        'id'           => '1',
        'jsonapi_type' => 'posts',
        'title'        => 'post title 1',
        'description'  => 'post description 1'
      })
    end

    context 'when no attributes' do
      before do
        response_json[:data].delete(:attributes)
      end

      it 'does not blow up' do
        expect(json_item).to eq({
          'id'           => '1',
          'jsonapi_type' => 'posts'
        })
      end
    end
  end

  describe '#json_items' do
    let(:response_json) { basic_posts_response }

    context 'when passing index' do
      it 'finds the item at the given index and merges id/type/attributes' do
        expect(json_items(1)).to eq({
          'id'           => '2',
          'jsonapi_type' => 'posts',
          'title'        => 'post title 2',
          'description'  => 'post description 2'
        })
      end
    end

    context 'when not passing index' do
      it 'finds all items' do
        expect(json_items.length).to eq(2)
      end
    end
  end

  describe '#json_ids' do
    let(:response_json) { basic_posts_response }

    it 'grabs all ids from the list' do
      expect(json_ids).to eq(%w(1 2))
    end

    context 'when casting as integers' do
      it 'casts all ids as integers' do
        expect(json_ids(true)).to eq([1, 2])
      end
    end
  end

  describe '#json_included_types' do
    let(:response_json) { included_response }

    it 'is a unique array of included types' do
      expect(json_included_types).to eq(%w(comments authors))
    end
  end

  describe '#json_includes' do
    let(:response_json) { included_response }

    context 'when no index passed' do
      it 'is all includes of given type' do
        expect(json_includes('comments').length).to eq(2)
      end
    end

    context 'when index passed' do
      it 'is only includes of a given type at indices' do
        expect(json_includes('comments', 1).length).to eq(1)
      end
    end
  end

  describe '#json_include' do
    let(:response_json) { included_response }

    it 'takes the first include of given type' do
      expect(json_include('comments')).to eq({
        'jsonapi_type' => 'comments',
        'id' => '456',
        'body' => 'comment1'
      })
    end

    context 'when passed index' do
      it 'takes the include of the given type at index' do

      end
    end
  end

  describe '#assert_payload' do
    before do
      JsonapiSpecHelpers::Payload.register(:post) do
        key(:title)
        key(:description)
        key(:first_title_letter) { |p| p.title[0] }
      end
    end

    let(:response_json) do
      json = basic_post_response
      json[:data][:attributes][:first_title_letter] = 'p'
      json
    end

    context 'when payload is valid' do
      let(:post_record) do
        double \
          id: 1,
          title: 'post title 1',
          description: 'post description 1'
      end

      it 'passes assertion' do
        assert_payload(:post, post_record, json_item)
      end

      context 'when json value does not match payload value' do
        before do
          allow(post_record).to receive(:title) { 'foo' }
        end

        it 'does not pass assertion' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /Expected JSON payload to have key 'title' == "foo" but was "post title 1"/
          )
        end
      end

      context 'when given timestamps! in payload' do
        let(:timestamp) { Time.now }

        before do
          JsonapiSpecHelpers::Payload.register(:post_with_timestamps) do
            key(:title)
            key(:description)
            timestamps!
          end

          response_json[:data][:attributes].delete(:first_title_letter)
          response_json[:data][:attributes][:created_at] = timestamp
          response_json[:data][:attributes][:updated_at] = timestamp
        end

        it 'should assert on created_at/updated_at' do
          expect(post_record).to receive(:created_at) { timestamp }
          expect(post_record).to receive(:updated_at) { timestamp }
          assert_payload(:post_with_timestamps, post_record, json_item)
        end
      end

      context 'when json contains payload key, but it is nil' do
        before do
          response_json[:data][:attributes].merge!(title: nil)
        end

        it 'does not pass assertion' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /but was nil/
          )
        end

        context 'and allow_nil is true' do
          before do
            JsonapiSpecHelpers::Payload.register(:post_with_nil_title) do
              key(:title, allow_nil: true)
              key(:description)
              key(:first_title_letter) { |p| p.title[0] }
            end
          end

          it 'does not throw an error' do
            expect {
              assert_payload(:post_with_nil_title, post_record, json_item)
            }.to_not raise_error
          end
        end
      end

      context 'when json does not contain payload key' do
        before do
          response_json[:data][:attributes].delete(:title)
        end

        it 'does not pass assertion' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /Expected JSON payload to have key 'title' but was not present/
          )
        end
      end

      context 'when json contains extra keys' do
        before do
          response_json[:data][:attributes][:foo] = 'bar'
        end

        it 'does not pass assertion' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /JSON payload contained unexpected key 'foo'/
          )
        end
      end

      context 'when no payloads registered for this name' do
        it 'raises an error' do
          expect {
            assert_payload(:asdf, post_record, json_item)
          }.to raise_error(/No payloads registered for 'asdf'/)
        end
      end

      context 'when asserting with customized block' do
        before do
          response_json[:data][:attributes][:title].upcase!
        end

        # Note this tests asserts errors are raised before and after to ensure
        # the block customization won't screw up future tests.
        it 'customizes assertions based on the block overrides' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)

          assert_payload(:post, post_record, json_item) do
            key(:title) { |r| r.title.upcase }
          end

          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end

        context 'when no_key is specified' do
          it 'asserts there is not a key present' do
            expect {
              assert_payload(:post, post_record, json_item) do
                no_key(:title)
              end
            }.to raise_error(
              RSpec::Expectations::ExpectationNotMetError,
              /Expected JSON payload to NOT have key 'title' but was present/
            )
          end
        end
      end
    end
  end
end
