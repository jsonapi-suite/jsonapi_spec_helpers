require 'jsonapi_spec_helpers'

::RSpec.shared_context 'resource testing', type: :resource do |parameter|
  let(:resource)     { described_class }
  let(:params)       { {} }

  # If you need to set context:
  #
  # JsonapiCompliable.with_context my_context, {} do
  #   render
  # end
  def render(runtime_options = {})
    json = proxy.to_jsonapi(runtime_options)
    response.body = json
    json
  end

  def proxy
    @proxy ||= begin
      ctx = ::JsonapiSpecHelpers::TestRunner.new(resource, params)
      defined?(base_scope) ? ctx.proxy(base_scope) : ctx.proxy
    end
  end

  def records
    proxy.data
  end

  def response
    @response ||= OpenStruct.new
  end
end

module JsonapiSpecHelpers
  module RSpec
    def self.included(klass)
      klass.send(:include, JsonapiSpecHelpers)

      ::RSpec.configure do |rspec|
        rspec.include_context "resource testing", type: :resource
      end
    end
  end
end
