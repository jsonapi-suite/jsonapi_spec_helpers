module JsonapiSpecHelpers
  class Payload
    class << self
      attr_accessor :registry
    end
    self.registry = {}

    attr_accessor :keys, :no_keys

    def self.register(name, &blk)
      instance = new
      instance.instance_eval(&blk)
      registry[name] = instance
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

    def key(name, options = {}, &blk)
      options[:allow_nil] ||= false
      @no_keys.reject! { |k| k == name }
      prc = blk
      prc = ->(record) { record.send(name) } if prc.nil?
      @keys[name] = options.merge(proc: prc)
    end

    def timestamps!
      @keys[:created_at] = key(:created_at)
      @keys[:updated_at] = key(:updated_at)
    end
  end
end
