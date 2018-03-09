module JsonapiSpecHelpers
  class Payload
    class << self
      attr_accessor :registry
    end
    self.registry = {}

    attr_accessor :name, :type, :keys, :no_keys

    def self.register(name, &blk)
      instance = new
      instance.instance_eval(&blk)
      instance.name = name
      registry[name] = instance
    end

    def self.by_type(type)
      found = nil
      registry.each_pair do |name, payload|
        found = payload if payload.type == type
      end
      raise "Could not find payload for type #{type}" unless found
      found
    end

    def fork
      instance = self.class.new
      instance.keys = keys.dup
      instance.no_keys = no_keys.dup
      instance
    end

    def initialize
      @keys = {}
      @no_keys = []
    end

    def no_key(name)
      @keys.delete(name)
      @no_keys << name
    end

    def type(val = nil)
      if val
        @type = val
      else
        @type || name.to_s.pluralize.to_sym
      end
    end

    def key(name, *args, &blk)
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:type] = args.first
      options[:allow_nil] ||= false
      @no_keys.reject! { |k| k == name }
      prc = blk
      prc = ->(record) { record.send(name) } if prc.nil?
      @keys[member_name_for(name, options)] = options.merge(proc: prc)
    end

    def timestamps!
      @keys[member_name_for(:created_at)] = key(:created_at, String)
      @keys[member_name_for(:updated_at)] = key(:updated_at, String)
    end

    def member_name_style(style = :underscore)
      @member_name_style = style
    end

    private

    def member_name_for(name, options = {})
      transform_method = options.fetch :member_name_style, (@member_name_style || :underscore)
      transform_method = :dasherize if transform_method == :hyphen
      name.to_s.send transform_method
    end
  end
end
