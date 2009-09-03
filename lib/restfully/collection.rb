require 'delegate'

module Restfully
  class Collection < DelegateClass(Hash)
    
    attr_reader :state, :raw, :uri, :session, :title
    
    def initialize(uri, session, options = {})
      @uri = uri
      @title = options['title']
      @session = session
      @raw = options['raw']
      @state = :unloaded
      @items = {}
      super(@items)
    end
    
    def loaded?;    @state == :loaded;    end
    
    def load(options = {})
      options = options.symbolize_keys
      force_reload = options.delete(:reload) || false
      path = uri
      if options.has_key?(:query)
        path, query_string = uri.split("?")
        query_string ||= ""
        query_string.concat(options.delete(:query).to_params)
        path = "#{path}?#{query_string}"
        force_reload = true
      end      
      if loaded? && force_reload == false
        self
      else
        @raw = session.get(path, options) if raw.nil? || force_reload
        raw.each do |key, value|
          next if key == 'links'
          self_link = (value['links'] || []).map{|link| Link.new(link)}.detect{|link| link.self?}
          if self_link && self_link.valid?
            @items.store(key, Resource.new(self_link.href, session, 'raw' => value).load)
          else
            session.logger.warn "Resource #{key} does not have a 'self' link. skipped."
          end
        end       
        @state = :loaded
        self
      end
    end
    
    
  end
end