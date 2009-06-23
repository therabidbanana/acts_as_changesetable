module ActsAsChangesetable
  module ChangeableChangeset
    # Upon including this module, mixin class methods
    def self.included(base)
      base.send :extend, ClassMethods
    end
    
    # Returns a list of changes associated with changeset_id
    # for all classes set in the changeable_histories option
    def changes
      @list = {}
      self.changeables_list.each do |name|
        @list[name] = name.to_s.constantize.find_all_by_changeset_id(self.id)
      end
      @list
    end
    
    # Accessor for the changeable_histories list
    def changeables_list
      self.class.changeables_list
    end
    
    # Batch synchronize will go through all of the changeables for a changeset and make sure 
    # all items are up to date by calling sync_changeable!
    def batch_synchronize
      # The dumb way to do this, call sync_changeable! for every changeable in the list
      # We'll need to find a better way to scale.
      changes = self.changes
      for name in changes
        changes[name].each{|history| history.changeable.sync_changeable!}
      end
    end
    
    
    module ClassMethods
      # Get the currently active changeset (useful so that you can then get a list of changes
      # for the current changeset)
      def active_changeset
        a = find_by_is_active(true)
        return a if a
        new_changeset
      end
      
      # Deactivate all changesets.
      def deactivate_changesets
        active_sets = find_all_by_is_active(true)
        active_sets.each{|s| s.is_active = false; s.save}
      end
      

      
      # Deactivate any currently active changesets, then create a new one and make it active.
      def new_changeset
        deactivate_changesets
        change = self.new
        change.is_active = true
        change.save
        change
      end
      
      # Accessor for the changeable_histories list
      def changeables_list
        self.changeable_histories
      end
    end
  end
end