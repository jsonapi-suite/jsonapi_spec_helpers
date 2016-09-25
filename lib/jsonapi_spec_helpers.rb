require 'json'
require 'jsonapi_spec_helpers/version'
require 'jsonapi_spec_helpers/payload'

RSpec::Matchers.define :match_payload do |attribute, expected|
  match do |actual|
    # cast to_json for things like Time
    actual.to_json == expected.to_json
  end

  failure_message do |actual|
    "Expected JSON payload to have key '#{attribute}' == #{expected.inspect} but was #{actual.inspect}"
  end
end

RSpec::Matchers.define :have_payload_key do |expected, allow_nil|
  match do |json|
    @has_key = json.has_key?(expected.to_s)
    @has_value = !json[expected.to_s].nil?

    if allow_nil
      @has_key
    else
      @has_key && @has_value
    end
  end

  failure_message do |actual|
    msg = !allow_nil && @has_key ? "nil. Use 'key(:foo, allow_nil: true)' to allow nils" : "not present"
    "Expected JSON payload to have key '#{expected}' but was #{msg}"
  end

  failure_message_when_negated do |actual|
    "Expected JSON payload to NOT have key '#{expected}' but was present"
  end
end

RSpec::Matchers.define :be_not_in_payload do |expected|
  match do |json|
    false
  end

  failure_message do |actual|
    "JSON payload contained unexpected key '#{actual}'"
  end
end

module JsonapiSpecHelpers
  def self.included(klass)
    if defined?(Rails)
      Dir[Rails.root.join('spec/payloads/**/*.rb')].each { |f| require f }
    end
  end

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

  def assert_payload(name, record, json, &blk)
    unless payload = JsonapiSpecHelpers::Payload.registry[name]
      raise "No payloads registered for '#{name}'"
    end

    # todo dup payload
    if blk
      payload = payload.fork
      payload.instance_eval(&blk)
    end

    aggregate_failures "payload has correct key/values" do
      payload.keys.each_pair do |attribute, options|
        prc = options[:proc]
        if (expect(json).to have_payload_key(attribute, options[:allow_nil])) == true
          unless options[:allow_nil]
            expect(json[attribute.to_s]).to match_payload(attribute, prc.call(record))
          end
        end
      end

      payload.no_keys.each do |no_key|
        expect(json).to_not have_payload_key(no_key, {})
      end

      unexpected_keys = json.keys - payload.keys.keys.map(&:to_s)
      unexpected_keys.reject! { |k| %w(id jsonapi_type).include?(k) }
      unexpected_keys.each do |key|
        expect(key).to be_not_in_payload
      end
    end
  end
end
