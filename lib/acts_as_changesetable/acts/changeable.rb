module ActsAsChangesetable
  module Changeable
    # Setup on mixin
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.changeable_setup
    end
    
    # Flag alerting the callbacks not to create history items on next save.
    # Set this as true to make a save with no history item associated. 
    # Use with caution, as this could put the data in an unvalid state.
    # This flag will be set if you use sync_changeable. 
    #
    # The flag is reset after every database operation.
    attr_accessor :no_history
    
    # Callback hooked into after_destroy that copies every field required into the history class.
    # Also associates the history with the current changeset
    def after_changeable_destroy
      self.changeable_history_class.new_from_changeable(self, true) unless (self.no_history || self.changesetable_options.no_copy_deleted?)
      self.no_history = false
      true
    end
    
    # Callback hooked into after_save that copies every field required into the history class.
    # Also associates the history with the current changeset
    def after_changeable_save
      self.changeable_history_class.new_from_changeable(self) unless self.no_history
      self.no_history = false
      true
    end
    
    # Callback hooked into after_create to force creation of change history item
    def after_changeable_create
      self.changeable_history_class.new_from_changeable(self, true) unless self.no_history
      self.no_history = false
      true
    end
    
    # Call to synchronize the changeable with the a version in history, default to latest revision
    # (can be used in case where we add change histories by other means - synchronization with 
    # a device, for instance) 
    # 
    # This call does not save automatically. Use sync_changeable! to do that.
    # Note that in using this call, you must be careful not to make other changes, since
    # no_history will be set to true
    def sync_changeable(history = false)
      history = self.latest_change unless history
      for field in self.changeable_fields
        self.send("#{field}=", history.send(field))
      end
      unless self.changesetable_options.no_copy_timestamps?
        self.updated_at = history.updated_at if(self.respond_to?(:updated_at) && history.respond_to?(:updated_at))
        self.created_at = history.created_at if(self.respond_to?(:created_at) && history.respond_to?(:created_at))
      end
      unless self.changesetable_options.no_copy_deleted?
        self.deleted_at = history.deleted_at if(self.respond_to?(:deleted_at) && history.respond_to?(:deleted_at))
      end
      self.no_history = true
      return self
    end
    
    # Does synchronization with save. No history item will be generated. 
    # Note that the no_history flag is set, but is disabled soon after by the save callback.
    def sync_changeable!(history = false)
      history = self.latest_change unless history
      self.sync_changeable(history)
      self.no_history = true
      self.save
      self
    end
    

    
    # Returns true if object is outdated, else returns false.
    def outdated?
      history = self.latest_change
      return (history.updated_at > self.updated_at) 
    end
    
    
    # Call to get latest history item for changeable. Usually used by sync_changeable.
    # Returns a ChangeableHistory item
    def latest_change
      self.changeable_history_class.get_latest_for self
    end
    
    # Returns an array of changes
    def changes
      self.changeable_history_class.get_changes_for self
    end
    
    
    module ClassMethods
      # Add callbacks to this class so we can mirror changes into our history classs
      def changeable_setup
        after_destroy :after_changeable_destroy
        after_update :after_changeable_save
        after_create :after_changeable_create
      end
      
      # Creates a new changeable from a history item if necessary
      def new_from_history(history)
        # create a new changeable 
        # (note: block syntax is only way to set primary key manually)
        new_guy = self.new do |c|
          c.id = history.send("#{changeable_fk}")    
          for field in c.changeable_fields
            c.send("#{field}=", history.send(field))
          end
          unless self.changesetable_options.no_copy_timestamps?
            c.updated_at = history.updated_at if(history.respond_to?(:updated_at) && c.respond_to?(:updated_at))
            c.created_at = history.created_at if(history.respond_to?(:created_at) && c.respond_to?(:created_at))
          end
          unless self.changesetable_options.no_copy_deleted?
            c.deleted_at = history.deleted_at if(history.respond_to?(:deleted_at) && c.respond_to?(:deleted_at))
          end
        end
        self.record_timestamps = false
        new_guy.save
        self.record_timestamps = true
        new_guy
      end
    end
  end
end