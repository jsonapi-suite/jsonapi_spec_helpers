require 'json'
require 'pp'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'jsonapi_compliable'

require 'jsonapi_spec_helpers/version'
require 'jsonapi_spec_helpers/helpers'
require 'jsonapi_spec_helpers/node'
require 'jsonapi_spec_helpers/errors_proxy'
require 'jsonapi_spec_helpers/errors'

module JsonapiSpecHelpers
  def self.included(klass)
    klass.send(:include, Helpers)
  end

  class TestRunner < ::JsonapiCompliable::Runner
    def current_user
      nil
    end
  end

  module Sugar
    def d
      jsonapi_data
    end

    def included(type = nil)
      jsonapi_included(type)
    end

    def errors
      jsonapi_errors
    end
  end
end
