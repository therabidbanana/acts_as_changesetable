# ActsAsChangesetable
require 'activesupport' unless defined? ActiveSupport
require 'activerecord' unless defined? ActiveRecord
require 'acts_as_changesetable/acts/changeable'
require 'acts_as_changesetable/acts/changeable_history'
require 'acts_as_changesetable/acts/common'
require 'acts_as_changesetable/acts/changeset'

module ActsAsChangesetable
  # Include class methods when this module is mixed into ActiveRecord::Base
  def self.included(base)
    base.send :extend, ClassMethods
  end
  
  # These methods extend ActiveRecord::Base
  module ClassMethods
    # Sets a class to be a changeable. See README for details
    def acts_as_changeable(*args, &block)
      self.send :include, Common
      changeable_common_setup(args, block)
      self.send :include, Changeable
    end
    
    # Sets a class to be a changeable_history. See README for details
    def acts_as_changeable_history(*args, &block)
      self.send :include, Common
      args = [{:same_as_changeable => true}] if args.size == 0 and !block_given?
      changeable_common_setup(args, block)
      self.send :include, ChangeableHistory
    end
    # Sets a class to be a changeset. See README for details
    def acts_as_changeset(*args, &block)
      cattr_accessor :changeable_histories
      self.send :include, ChangeableChangeset
      opts = args.extract_options!
      self.changeable_histories = opts[:changeable_histories]
    end
  end
end

ActiveRecord::Base.send :include, ActsAsChangesetable