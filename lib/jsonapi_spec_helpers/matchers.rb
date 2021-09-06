require 'rspec/matchers'
require 'jsonapi_spec_helpers/string_helpers'

RSpec::Matchers.define :match_payload do |attribute, expected|
  match do |actual|
    if expected.respond_to?(:as_json)
      expected = expected.as_json
    end

    actual == expected
  end

  failure_message do |actual|
    "Expected JSON payload to have key '#{attribute}' == #{expected.inspect} but was #{actual.inspect}"
  end
end

RSpec::Matchers.define :match_type do |attribute, type|
  match do |actual|
    if type.is_a?(Array)
      type.any? { |t| actual.is_a?(t) }
    else
      actual.is_a?(type)
    end
  end

  failure_message do |actual|
    "Expected JSON payload key '#{attribute}' to have type #{type} but was #{actual.class}"
  end
end

RSpec::Matchers.define :have_payload_key do |expected, allow_nil, dasherized|
  match do |json|
    expected = dasherized ? JsonapiSpecHelpers::StringHelpers.dasherize(expected) : expected.to_s
    @has_key = json.has_key?(expected)
    @has_value = !json[expected].nil?

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
