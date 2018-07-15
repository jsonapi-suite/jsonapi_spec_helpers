module JsonapiSpecHelpers
  module Helpers
    extend ActiveSupport::Concern

    def json
      if response && response.body
        JSON.parse(response.body).with_indifferent_access
      else
        raise Errors::NoResponse.new
      end
    end

    def jsonapi_data
      @jsonapi_data ||= begin
        if _jsonapi_data.is_a?(Hash)
          node(from: _jsonapi_data)
        else
          _jsonapi_data.map { |datum| node(from: datum) }
        end
      end
    end

    def jsonapi_included(type = nil)
      variable = :"@jsonapi_included#{type}"
      memo = instance_variable_get(variable)
      return memo if memo

      nodes =  _jsonapi_included.map { |i| node(from: i) }
      if type
        nodes.select! { |n| n.jsonapi_type == type }
      end
      instance_variable_set(variable, nodes)
      nodes
    end

    def jsonapi_errors
      @jsonapi_errors ||= ErrorsProxy.new(json['errors'] || [])
    end

    def jsonapi_headers
      {
        'CONTENT_TYPE' => 'application/vnd.api+json'
      }
    end

    def jsonapi_get(url, params: {})
      get url, params: params, headers: jsonapi_headers
    end

    def jsonapi_post(url, payload)
      post url, params: payload.to_json, headers: jsonapi_headers
    end

    def jsonapi_put(url, payload)
      put url, params: payload.to_json, headers: jsonapi_headers
    end

    def jsonapi_patch(url, payload)
      patch url, params: payload.to_json, headers: jsonapi_headers
    end

    def jsonapi_delete(url)
      delete url, headers: jsonapi_headers
    end

    def datetime(value)
      JsonapiCompliable::Types[:datetime][:test][value]
    end

    # @api private
    def node(from: nil)
      from = json if from.nil?
      data = from.has_key?('data') ? from['data'] : from
      hash = {}
      hash['id'] = data['id']
      hash['jsonapi_type'] = data['type']
      hash.merge!(data['attributes']) if data.has_key?('attributes')
      Node.new(hash, data['relationships'], self)
    end

    private

    # @api private
    def _jsonapi_data
      json['data'] || raise(Errors::NoData.new(json))
    end

    # @api private
    def _jsonapi_included
      if json.has_key?('included')
        json['included']
      else
        raise Errors::NoSideloads.new(json)
      end
    end
  end
end
