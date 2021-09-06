require 'json'
require 'jsonapi_spec_helpers/version'
require 'jsonapi_spec_helpers/helpers'
require 'jsonapi_spec_helpers/string_helpers'
require 'jsonapi_spec_helpers/payload'
require 'jsonapi_spec_helpers/payload_sanitizer'
require 'jsonapi_spec_helpers/errors'

module JsonapiSpecHelpers
  def self.included(klass)
    # don't load RSpec until included
    require 'jsonapi_spec_helpers/matchers'
    klass.send(:include, Helpers)
    if defined?(Rails)
      load_payloads!
    end
  end

  def self.load_payloads!
    Dir[Rails.root.join('spec/payloads/**/*.rb')].each { |f| require f }
  end

  def assert_payload(name, record, json, dasherized: false, &blk)
    unless payload = JsonapiSpecHelpers::Payload.registry[name]
      raise "No payloads registered for '#{name}'"
    end

    if blk
      payload = payload.fork
      payload.instance_eval(&blk)
    end

    aggregate_failures "payload has correct key/values" do
      payload.keys.each_pair do |attribute, options|
        prc = options[:proc]
        if (expect(json).to have_payload_key(attribute, options[:allow_nil], dasherized)) == true
          unless options[:allow_nil]
            output = instance_exec(record, &prc)
            attribute = attribute.to_s
            attribute = StringHelpers.dasherize(attribute) if dasherized
            expect(json[attribute]).to match_payload(attribute, output)

            if options[:type]
              expect(json[attribute.to_s]).to match_type(attribute, options[:type])
            end
          end
        end
      end

      payload.no_keys.each do |no_key|
        expect(json).to_not have_payload_key(no_key, {})
      end
      unexpected_keys = json.keys - payload.keys.keys.map do |key|
        dasherized ? StringHelpers.dasherize(key) : key.to_s
      end
      unexpected_keys.reject! { |k| %w(id jsonapi_type).include?(k) }
      unexpected_keys.each do |key|
        expect(key).to be_not_in_payload
      end
    end
  end
end
