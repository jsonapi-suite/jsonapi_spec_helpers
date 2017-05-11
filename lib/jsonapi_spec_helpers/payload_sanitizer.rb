module JsonapiSpecHelpers
  class PayloadSanitizer
    def initialize(payload)
      @payload = payload
      @included = []
    end

    def resource
      @resource ||= sane_resource(@payload)
    end

    def sanitize
      resource[:relationships].each_pair do |key, relationship_payload|
        set_default_relationship_payload(key, relationship_payload)

        if relationship_payload.is_a?(Array)
          relationship_payload.each do |p|
            process_relationship(key, p)
          end
        else
          process_relationship(key, relationship_payload)
        end
      end

      payload = { data: data }
      payload[:included] = @included
      payload
    end

    def included
      @included
    end

    def add_include(incl)
      @included.push(incl) if @included.index(incl).nil?
    end

    def resource_identifier
      {}.tap do |ri|
        ri[:id]   = resource[:id] if resource[:id]
        ri[:type] = resource[:type]
      end
    end

    def data
      @data ||= {}.tap do |d|
        d[:id]         = resource[:id] if resource[:id]
        d[:type]       = resource[:type]
        d[:attributes] = resource[:attributes]
      end
    end

    private

    def set_default_relationship_payload(key, payload)
      data[:relationships] ||= {}
      if payload.is_a?(Array)
        data[:relationships][key] ||= { data: [] }
      else
        data[:relationships][key] ||= { data: nil }
      end
    end

    def process_relationship(name, relationship_payload)
      sanitizer = self.class.new(relationship_payload)

      if data[:relationships][name][:data].is_a?(Array)
        data[:relationships][name][:data] << sanitizer.resource_identifier
      else
        data[:relationships][name] = { data: sanitizer.resource_identifier }
      end

      sanitized = sanitizer.sanitize
      add_include(sanitized[:data])
      sanitized[:included].each do |incl|
        add_include(incl)
      end
    end

    def sane_resource(payload)
      id, type = payload.delete(:id), payload.delete(:type)
      relationships = payload.delete(:relationships) || {}
      raise 'jsonapi payloads must specify a "type"' if type.nil?

      {
        id: id,
        type: type,
        attributes: payload,
        relationships: relationships
      }
    end
  end
end
