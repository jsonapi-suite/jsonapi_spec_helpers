require 'spec_helper'

describe JsonapiSpecHelpers do
  include JsonapiSpecHelpers
  attr_accessor :response

  let(:instance) { klass.new }

  let(:show_json) do
    {
      'data' => {
        'type' => 'posts',
        'id' => '1',
        'attributes' => {
          'title' => 'post title',
          'description' => 'post description'
        }
      }
    }
  end

  let(:index_json) do
    {
      'data' => [
        {
          'type' => 'posts',
          'id' => '1',
          'attributes' => {
            'title' => 'post title',
            'description' => 'post description'
          }
        },
        {
          'type' => 'posts',
          'id' => '2',
          'attributes' => {
            'title' => 'another title',
            'description' => 'another description'
          }
        }
      ]
    }
  end

  let(:include_json) do
    {
      'included' => [
        {
          'type' => 'comments',
          'id' => '1',
          'attributes' => {
            'text' => 'my comment'
          }
        },
        {
          'type' => 'comments',
          'id' => '2',
          'attributes' => {
            'text' => 'another comment'
          }
        },
        {
          'type' => 'authors',
          'id' => '9',
          'attributes' => {
            'name' => 'Joe Author'
          }
        }
      ]
    }
  end

  describe '#json_item' do
    let(:json) { show_json }

    it 'merges id/type/attributes' do
      expect(json_item).to eq({
        'id'           => '1',
        'jsonapi_type' => 'posts',
        'title'        => 'post title',
        'description'  => 'post description'
      })
    end

    context 'when no attributes' do
      before do
        json['data'].delete('attributes')
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
    let(:json) { index_json }

    context 'when passing index' do
      it 'finds the item at the given index and merges id/type/attributes' do
        expect(json_items(1)).to eq({
          'id'           => '2',
          'jsonapi_type' => 'posts',
          'title'        => 'another title',
          'description'  => 'another description'
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
    let(:json) { index_json }

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
    let(:json) { include_json }

    it 'is a unique array of included types' do
      expect(json_included_types).to eq(%w(comments authors))
    end
  end

  describe '#json_includes' do
    let(:json) { include_json }

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
    let(:json) { include_json }

    it 'takes the first include of given type' do
      expect(json_include('comments')).to eq({
        'jsonapi_type' => 'comments',
        'id' => '1',
        'text' => 'my comment'
      })
    end
  end
end
