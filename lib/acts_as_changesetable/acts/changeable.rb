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
    # The flag is reset after every save operation.
    attr_accessor :no_history
    
    # Callback hooked into after_save that copies every field required into the history class.
    # Also associates the history with the current changeset
    def after_changeable_save
      self.changeable_history_class.new_from_changeable self unless self.no_history
      self.no_history = false
    end
    
    # Callback hooked into after_create to force creation of change history item
    def after_changeable_create
      self.changeable_history_class.new_from_changeable self, true unless self.no_history
      self.no_history = false
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
      # Split into two classes because dirty tracking returns false for new objects. 
      # (Which sort of makes sense. I can't find an "unsaved" ActiveModel method though, which
      # I imagine should exist somewhere.)
      # 
      # self.new_record? <- found it.
      # Don't need the separate callbacks any more... unless it doesn't work...
      # Testing shows new_record? is returning false for new records. Wonder why that is.
      def changeable_setup
        after_update :after_changeable_save
        after_create :after_changeable_create
      end
    end
  end
end