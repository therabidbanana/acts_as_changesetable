module ActsAsChangesetable
  # Simple class for evaluating options and allowing us to access them
  # The options will not be mutable at runtime.
  class Options
    def initialize(*options, &block)
      @lock = false
      @copy = false
      @options = options.extract_options!
      @options.default = nil
      @copy = true if @options[:same_as_changeable]
      instance_eval(&block) if block_given?
      @lock = true
      @options[:copy] = true if @copy
    end

    def method_missing(key, *args)
      if(key.to_s == 'same_as_changeable') 
        @options[:copy] = true
      end
      return (@options[key.to_s.gsub(/\?$/, '').to_sym].eql?(true)) if key.to_s.match(/\?$/)
      if args.blank?
        @options[key.to_sym]
      elsif(key.to_s.match(/\=$/))
        @options[key.to_s.gsub(/\=$/, '').to_sym] = (args.size == 1 ? args.first : args) unless @lock
        raise 'Trying to change immutable options at runtime' if @lock
      else
        @options[key.to_sym] = (args.size == 1 ? args.first : args) unless @lock
        raise 'Trying to change immutable options at runtime' if @lock
      end
    end
  end
end