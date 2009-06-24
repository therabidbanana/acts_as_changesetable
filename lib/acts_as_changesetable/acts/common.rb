module ActsAsChangesetable
  module Common
    # Include some class methods
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
    
    # A convenience method for accessing the class method changesetable_options
    def changesetable_options
      self.changesetable_options
    end
    
    # A convenience method for accessing the class method changeable_class
    def changeable_class
      self.class.changeable_class
    end
    
    # A convenience method for accessing the class method changeable_history_class
    def changeable_history_class
      self.class.changeable_history_class
    end
    
    # A convenience method for accessing the class method changeable_fk
    def changeable_fk
      self.class.changeable_fk
    end
    
    # A convenience method for accessing the class method changeable_fields
    def changeable_fields
      self.class.changeable_fields(self)
    end
    
    # A convenience method for accessing the class method changeable_class
    def changeset_class
      self.class.changeset_class
    end
    

    
    module ClassMethods
      
      # Sets up the options
      def changeable_common_setup(args, block)
        cattr_accessor :changesetable_options
        options = args.extract_options!
        self.changesetable_options = Options.new(options, &block)
        self.changesetable_options = changeable_class.changesetable_options if self.changesetable_options.copy
      end
      
      # Returns the main class
      def changeable_class
        if(self.changesetable_options.changeable_class)
          self.changesetable_options.changeable_class.to_s.constantize 
        elsif(self.to_s.match(/History$/))
            self.to_s.gsub(/History$/, '').constantize
        else
          self
        end
      rescue NameError  
        klass = (self.changesetable_options.changeable_class.to_s || (self.to_s.gsub(/History$/, '')))
        raise "Can't convert to class name. Is this class defined? -> " + klass
      end
      
      # Returns the main class' name
      def changeable_class_name
        if(self.changesetable_options.changeable_class)
          self.changesetable_options.changeable_class.to_s 
        elsif(self.to_s.match(/History$/))
            self.to_s.gsub(/History$/, '')
        else
          self.to_s
        end
      end

      # Returns the history class
      def changeable_history_class
        if(self.changesetable_options.changeable_history_class)
          self.changesetable_options.changeable_history_class.to_s.constantize 
        elsif(self.to_s.match(/History$/))
            self
        else
          (self.to_s + "History").constantize
        end
      rescue NameError
        klass = (self.changesetable_options.changeable_history_class.to_s || (self.to_s + "History"))
        raise "Can't convert to class name. Is this class defined? -> " + klass
      end
      
      # Returns the history class' name
      def changeable_history_class_name
        if(self.changesetable_options.changeable_history_class)
          self.changesetable_options.changeable_history_class.to_s 
        elsif(self.to_s.match(/History$/))
            self.to_s
        else
          (self.to_s + "History")
        end
      end
      
      # Returns the changeset class  
      def changeset_class
        if(self.changesetable_options.changeset_class)
          self.changesetable_options.changeset_class.constantize
        else
          "Changeset".constantize
        end
      rescue NameError  
        klass = (self.changesetable_options.changeset_class.to_s || ("Changeset"))
        raise "Can't convert to class name. Is this class defined? -> " + klass
      end
      
      # Returns the changeset class name
      def changeset_class_name
        if(self.changesetable_options.changeset_class)
          self.changesetable_options.changeset_class.to_s
        else
          "Changeset"
        end
      end
      
      # Returns the changeable foreign key name that will be used
      def changeable_fk
        if(self.changesetable_options.changeable_fk)
          self.changesetable_options.changeable_fk
        else
          "#{self.changeable_class_name.downcase}_id".to_sym
        end
      end
      
      # Returns a list of changeable fields
      def changeable_fields(for_changeable = false)
        list = []
        for_changeable.attributes.each{|k,v| list << k unless [:updated_at, :created_at, :deleted_at, :id].include?(k)} if for_changeable
        return list if (for_changeable && !self.changesetable_options.fields)
        return self.changesetable_options.fields 
      end
    end
  end
end