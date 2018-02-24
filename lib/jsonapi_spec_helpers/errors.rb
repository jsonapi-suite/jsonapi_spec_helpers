module JsonapiSpecHelpers
  module Errors
    class Base < StandardError; end
    class IncludedOutOfBounds < Base
      def initialize(type, index, array)
        @type = type; @index = index; @array = array
      end

      def message
        "You attempted to get an item at index #{@index} of the type '#{@type}' " \
        "from the included property of your JSON payload. But it contained "    \
        "#{@array.length} '#{@type}'"
      end
    end
  end
end