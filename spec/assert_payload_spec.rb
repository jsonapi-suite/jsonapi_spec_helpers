require 'spec_helper'

describe JsonapiSpecHelpers do
  include JsonapiSpecHelpers
  attr_accessor :response

  let(:instance) { klass.new }

  let(:json) do
    {
      'data' => {
        'type' => 'posts',
        'id' => '1',
        'attributes' => {
          'title' => 'post title',
          'description' => 'post description',
          'views' => 100,
          'first_title_letter' => 'p'
        }
      }
    }
  end

  after do
    JsonapiSpecHelpers::Payload.registry = {}
  end

  describe '#assert_payload' do
    before do
      JsonapiSpecHelpers::Payload.register(:post) do
        key(:title)
        key(:description)
        key(:first_title_letter) { |p| p.title[0] }
        key(:views, Integer)
      end
    end

    let(:post_record) do
      double \
        id: 1,
        title: 'post title',
        description: 'post description',
        views: 100
    end

    context 'when payload is valid' do
      it 'passes assertion' do
        assert_payload(:post, post_record, json_item)
      end

      context 'when json value matches payload value, but wrong type' do
        before do
          json['data']['attributes']['views'] = '100'
          allow(post_record).to receive(:views) { '100' }
        end

        it 'does not pass assertion' do
          expect {
            assert_payload(:post, post_record, json_item)
          }.to raise_error(
            RSpec::Expectations::ExpectationNotMetError,
            /Expected JSON payload key 'views' to have type Integer but was String/
          )
        end
      end

      context 'when a condition that matches multiple types' do
        it 'passes assertion if one of the types passes' do
          json['data']['attributes']['is_foo'] = false
          allow(post_record).to receive(:is_foo) { false }
          expect {
            assert_payload(:post, post_record, json_item) do
              key(:is_foo, [TrueClass, FalseClass])
            end
          }.to_not raise_error

          json['data']['attributes']['is_foo'] = true
          allow(post_record).to receive(:is_foo) { true }
          expect {
            assert_payload(:post, post_record, json_item) do
              key(:is_foo, [TrueClass, FalseClass])
            end
          }.to_not raise_error

          json['data']['attributes']['is_foo'] = 'true'
          allow(post_record).to receive(:is_foo) { 'true' }
          expect {
            assert_payload(:post, post_record, json_item) do
              key(:is_foo, [TrueClass, FalseClass])
            end
          }.to raise_error(RSpec::Expectations::ExpectationNotMetError)
        end
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
            /Expected JSON payload to have key 'title' == "foo" but was "post title"/
          )
        end
      end

      context 'when given timestamps! in payload' do
        let(:timestamp) { Time.now.to_json }

        before do
          JsonapiSpecHelpers::Payload.register(:post_with_timestamps) do
            key(:title)
            key(:description)
            key(:views)
            timestamps!
          end

          json['data']['attributes'].delete('first_title_letter')
          json['data']['attributes']['created_at'] = timestamp
          json['data']['attributes']['updated_at'] = timestamp
        end

        it 'should assert on created_at/updated_at' do
          expect(post_record).to receive(:created_at) { timestamp }
          expect(post_record).to receive(:updated_at) { timestamp }
          assert_payload(:post_with_timestamps, post_record, json_item)
        end
      end

      context 'when json contains payload key, but it is nil' do
        before do
          json['data']['attributes'].merge!('title' => nil)
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
              key(:views)
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
          json['data']['attributes'].delete('title')
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
          json['data']['attributes']['foo'] = 'bar'
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
          json['data']['attributes']['title'].upcase!
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

    context 'when payload contains a "relationship-only" item' do
      before do
        JsonapiSpecHelpers::Payload.register(:no_attribute_item) do
        end
      end

      let(:no_attribute_record) do
        double \
          id: 1,
          posts: post_record
      end

      let(:json) do
        {
          'data' => {
            'type' => 'no_attributes_items',
            'id' => '1',
            'relationships' => {
              'posts' => {
                'data' => [
                  {'type' => 'posts', 'id' => '1'}
                ]
              }
            }
          }
        }
      end

      it 'still properly throws when no item is present' do
        empty_json_item = {'id' => nil, 'jsonapi_type' => nil}
        expect {
          assert_payload(:no_attribute_item, no_attribute_record, empty_json_item)
        }.to raise_error(
          RSpec::Expectations::ExpectationNotMetError
        )
      end
    end
  end
end
