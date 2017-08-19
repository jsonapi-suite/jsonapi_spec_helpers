module JsonapiSpecHelpers
  module Helpers
    def json
      JSON.parse(response.body)
    end

    def json_item(from: nil)
      from = json if from.nil?
      data = from.has_key?('data') ? from['data'] : from

      {}.tap do |item|
        item['id'] = data['id']
        item['jsonapi_type'] = data['type']
        item.merge!(data['attributes']) if data.has_key?('attributes')
      end
    end

    def json_items(*indices)
      items   = []
      json['data'].each_with_index do |datum, index|
        included = indices.empty? || indices.include?(index)
        items << json_item(from: datum) if included
      end
      indices.length == 1 ? items[0] : items
    end

    def json_related_link(payload, assn_name)
      link = payload['relationships'][assn_name]['links']['related']['href']
      fail "link for #{assn_name} not found" unless link
      URI.decode(link)
    end

    def json_included_types
      (json['included'] || []).map { |i| i['type'] }.uniq
    end

    def json_includes(type, *indices)
      included = (json['included'] || []).select { |data| data['type'] == type }
      indices  = (0...included.length).to_a if indices.empty?
      includes = []
      indices.each do |index|
        includes << json_item(from: included.at(index))
      end
      includes
    end

    def json_include(type, index = 0)
      json_includes(type, index)[0]
    end

    def json_ids(integers = false)
      ids = json['data'].map { |d| d['id'] }
      ids.map!(&:to_i) if integers
      ids
    end

    def jsonapi_headers
      {
        'CONTENT_TYPE' => 'application/vnd.api+json'
      }
    end

    def jsonapi_post(url, payload)
      post url, params: payload.to_json, headers: jsonapi_headers
    end

    def jsonapi_put(url, payload)
      put url, params: payload.to_json, headers: jsonapi_headers
    end

    def jsonapi_delete(url)
      delete url, headers: jsonapi_headers
    end

    def jsonapi_payload(input)
      PayloadSanitizer.new(input).sanitize
    end
  end
end
