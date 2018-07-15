module JsonapiSpecHelpers
  class ErrorsProxy
    class Error
      attr_reader :json

      def initialize(json)
        @json = json
      end

      def attribute
        @json[:meta][:attribute]
      end

      # TODO: move to top-level code in errorable
      def code
        @json[:meta][:code]
      end

      def message
        @json[:meta][:message]
      end

      def title
        @json[:title]
      end

      def detail
        @json[:detail]
      end

      def status
        @json[:status]
      end
    end

    include Enumerable

    def initialize(array)
      @errors = array.map { |e| Error.new(e) }
    end

    def [](key)
      @errors[key]
    end

    def each(&blk)
      @errors.each(&blk)
    end

    def length
      count
    end

    def to_h
      {}.tap do |hash|
        @errors.each do |e|
          hash[e.attribute] = e.message
        end
      end
    end

    def method_missing(id, *args, &blk)
      if error = @errors.find { |e| e.attribute == id }
        return error
      else
        super
      end
    end
  end
end
