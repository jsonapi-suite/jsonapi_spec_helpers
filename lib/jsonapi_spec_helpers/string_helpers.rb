module JsonapiSpecHelpers
  class StringHelpers
    class << self
      def dasherize(attribute)
        return attribute.to_s unless attribute.to_s.include?('_')

        attribute.to_s.gsub('_','-')
      end
    end
  end
end
