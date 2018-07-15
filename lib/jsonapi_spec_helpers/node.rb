module JsonapiSpecHelpers
  class Node
    attr_reader :attributes, :relationships

    def initialize(attributes, relationships, context)
      @attributes = attributes.with_indifferent_access
      @relationships = relationships
      @context = context
    end

    def id
      rawid.to_i
    end

    def rawid
      @attributes['id']
    end

    def jsonapi_type
      @attributes['jsonapi_type']
    end

    def has_key?(key)
      @attributes.has_key?(key)
    end

    def [](key)
      @attributes[key] || @attributes[key.to_s]
    end

    def []=(key, val)
      @attributes[key] = val
    end

    def attributes
      @attributes
    end

    def method_missing(id, *args, &blk)
      if @attributes.has_key?(id)
        @attributes[id]
      else
        super
      end
    end

    def link(relationship_name, name)
      if @relationships.has_key?(relationship_name)
        links = @relationships[relationship_name][:links]
        raise Errors::LinksNotFound.new(relationship_name) unless links
        links[name]
      else
        raise Errors::SideloadNotFound.new(relationship_name)
      end
    end

    def sideload(relationship_name)
      unless @relationships.has_key?(relationship_name)
        raise Errors::SideloadNotFound.new(relationship_name)
      end
      rel = @relationships[relationship_name]
      rel = rel[:data]
      return if rel.nil?
      if rel.is_a?(Hash)
        include_for(rel[:type], rel[:id])
      else
        rel.map { |r| include_for(r[:type], r[:id]) }
      end
    end
    alias :sideloads :sideload

    private

    def include_for(type, id)
      data = @context.json[:included].find do |i|
        i[:type] == type && i[:id] == id
      end
      @context.node(from: data)
    end
  end
end
