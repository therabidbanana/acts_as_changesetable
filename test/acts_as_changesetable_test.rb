require File.dirname(__FILE__) + '/test_helper'

# Setting up class foo with fields and the copy_timestamps option.
# History will be tracked by FooHistory
class Foo < ActiveRecord::Base
  acts_as_changeable :fields => [:field1, :field2], :copy_timestamps => true
end

# Setting up FooHistory to access the changeable Foo
# Use the same_as_changeable option, since it should be the same
class FooHistory < ActiveRecord::Base
  acts_as_changeable_history :same_as_changeable => true
end

# Setting up a generic changeset, make it track FooHistory
class Changeset < ActiveRecord::Base
  acts_as_changeset :changeable_histories => ["FooHistory"]
end

class BarHistory < ActiveRecord::Base
  acts_as_changeable_history do
    changeable_history_class :FooHistory
    changeable_class 'Foo'
  end
end

class BazHistory < ActiveRecord::Base
  acts_as_changeable_history :changeable_history_class => 'Baz'
end

class Apple < ActiveRecord::Base
  acts_as_changeable
end

class AppleHistory < ActiveRecord::Base
  acts_as_changeable_history
end

class SameHistory < ActiveRecord::Base
  acts_as_changeable_history do
    changeable_class 'Foo'
    same_as_changeable
  end
end

# Test ActsAsChangeable
class ActsAsChangesetableTest < ActiveSupport::TestCase  
  load_schema
  def setup
    @foo = Foo.new
    @opts = ActsAsChangesetable::Options.new({:baz => 'baz'})
    @opts2 = ActsAsChangesetable::Options.new({:baz => 'baz'}) do
      foo 'foo'
    end
  end
  def teardown
    Foo.find(:all).each{|e| e.delete}
    Changeset.find(:all).each{|e| e.delete}
    FooHistory.find(:all).each{|e| e.delete}
    Apple.find(:all).each{|e| e.delete}
    AppleHistory.find(:all).each{|e| e.delete}
  end
  # Make sure the options get set.
  def test_options_hash
    assert_not_nil(@opts)
    assert_not_nil(@opts.baz)
    assert_equal 'baz', @opts.baz
  end
  # Make sure we can't change the options at runtime
  def test_options_immutable
    assert_not_nil(@opts)
    assert_nil(@opts.bar)
  end
  # Test passing options block style
  def test_options_block
    assert_not_nil(@opts2)
    assert_not_nil(@opts2.foo)
    assert_equal 'foo', @opts2.foo
    assert_equal 'baz', @opts2.baz
  end
  # Test that trying to change options on a changesetable object raises an error
  # (If we can change the history class in runtime, we could end up with integrity issues)
  def test_changesetable_options_immutable
    assert_not_nil(Foo.changesetable_options)
    assert_raise RuntimeError do
      Foo.changesetable_options.test = 'changed' 
    end
    assert_nil Foo.changesetable_options.test
  end
  # Make sure that if a class says to use the same options, they really do use the same options
  def test_options_same
    assert_equal Foo.changesetable_options, SameHistory.changesetable_options
    assert_equal Foo.changesetable_options, FooHistory.changesetable_options
  end
  
  # Test that options array is easily accessible through instance methods as well (for convenience)
  def test_changesetable_options_accessible_on_instances
    assert_not_nil(@foo.changesetable_options)
  end
  
  # Test that options for different classes are different (unless they have been tested as the same above)
  def test_changesetable_options_are_separate
    assert_not_equal BarHistory.changesetable_options, FooHistory.changesetable_options
    assert_not_equal BarHistory.changesetable_options, BazHistory.changesetable_options
  end
  # Test that when we set the copy timestamps option, the FooHistory class rails updated_at column doesn't 
  # do the normal automagic update.
  # With this, we can track the updated at as part of the history class without Rails interfering 
  def test_copy_timestamps_disables_timestamps_on_history_class
    f = FooHistory.new
    f.updated_at = 10.days.from_now
    f.save
    f = FooHistory.find(:first)
    assert 2.days.from_now < f.updated_at
  end
  
  # Test that the options are set to what we want them to be set to
  def test_changesetable_options_set
    assert_equal :FooHistory, BarHistory.changesetable_options.changeable_history_class
    assert_equal 'Foo', BarHistory.changesetable_options.changeable_class
    assert_equal true, Foo.changesetable_options.copy_timestamps?
    assert_equal true, FooHistory.changesetable_options.copy_timestamps?
    assert_equal false, FooHistory.record_timestamps
  end
  
  # Test that the class methods return instances of classes
  # Unless they aren't set, in which case we get an error.
  def test_class_access_methods
    assert_kind_of(Class, Foo.changeable_class) 
    assert_kind_of(Class, Foo.changeable_history_class)
    assert_kind_of(Class, FooHistory.changeable_class)
    assert_kind_of(Class, FooHistory.changeable_history_class)
    assert_kind_of(Class, BarHistory.changeable_class)
    assert_kind_of(Class, BarHistory.changeable_history_class)
    assert_raise (RuntimeError) { BazHistory.changeable_class }
    assert_raise (RuntimeError) { BazHistory.changeable_history_class }
  end
  
  # Make sure we get the right model for each class.
  def test_acts_as_changeable_gives_correct_history_model
    assert_equal 'Foo', Foo.changeable_class.to_s
    assert_equal 'FooHistory', Foo.changeable_history_class.to_s
    assert_equal 'Foo', FooHistory.changeable_class.to_s
    assert_equal 'FooHistory', FooHistory.changeable_history_class.to_s
  end
  # Test to make sure we get new history items when we save changes
  def test_save_on_changeable_triggers_save_on_history
    a = Foo.new
    a.field1 = 'a'
    a.field2 = 'b'
    a.field3 = 'c'
    a.save
    b = FooHistory.find_by_foo_id(a.id)
    assert_not_nil b
    assert_equal a.field1, b.field1
    assert_equal a.field2, b.field2
    assert_in_delta a.updated_at, b.updated_at, 1
    assert_in_delta a.created_at, b.created_at, 1
    a.field2 = 'd'
    a.save
    arr = FooHistory.find_all_by_foo_id(a.id)
    assert_equal 2, arr.size
    assert_in_delta a.created_at, arr[0].created_at, 1
    assert_in_delta a.created_at, arr[1].created_at, 1
  end
  # Test that we only save history items for changes on tracked columns.
  def test_changeable_only_creates_history_on_dirty_tracked_column
    a = Foo.new
    a.field1 = 'a'
    a.field2 = 'b'
    a.field3 = 'c'
    a.save
    a.field3 = 'd'
    a.save
    assert_equal 1, a.changes.size
    a.field1 = 'b'
    a.save
    assert_equal 2, a.changes.size
    a.field1 = 'b'
    assert_equal 2, a.changes.size
  end
  # Note we need to sleep here to ensure history works correctly.
  def test_changeable_has_history_functions 
    a = Foo.new
    a.field1 = 'a'
    a.field2 = 'b'
    a.field3 = 'c'
    a.save
    a.field3 = 'a'
    a.save
    sleep 1
    a.field2 = 'a'
    a.save
    b = Foo.new
    b.field1 = 'a'
    b.field2 = 'c'
    b.field3 = 'd'
    b.save
    sleep 1
    b.field1 = 'b'
    b.save
    sleep 1
    b.field1 = 'c'
    b.save
    b.updated_at=  b.updated_at+ 1.days
    b.field1 = 'd'
    c = FooHistory.new_from_changeable(b, true)
    assert_equal 2, a.changes.size
    x = b.changes[0]
    y = b.changes[1]
    z = b.changes[2]
    q = b.changes[3]
    # Check change history is ordered oldest to newest
    assert x.updated_at < y.updated_at
    assert y.updated_at < z.updated_at
    assert z.updated_at < q.updated_at
    # Check latest change is the one it should be.
    assert_equal 'd', b.latest_change.field1
    # Check syncing changeable updates field1
    assert_equal 'd', b.sync_changeable.field1
    # Check that changes are ignored for sync changeable if we throw away object.
    id = b.id
    b = Foo.find(id)
    assert_equal 'c', b.field1
    # Check that b knows it's outdated
    assert b.outdated?
    # Check that we can get b by the history item.
    b = c.changeable
    assert_kind_of(Foo, b)
    assert_equal(id, b.id)
    # Check that sync_changeable! works and saves to db
    assert_equal 'd', b.sync_changeable!.field1
    b = Foo.find(id)
    assert_equal 'd', b.field1
    # Assert there are only four changes to the db.
    assert_equal 4, b.changes.size
  end
  # Test that changesets are autocreated
  def test_changeset_created_on_save
    a = Foo.new
    a.save
    f = FooHistory.find(:first)
    c = Changeset.find_by_is_active(true)
    assert_not_nil c
  end
  # Test that history items are auto-assigned to changesets (which are autocreated if necessary)
  def test_changeable_history_assigned_to_changeset
    a = Foo.new
    a.save
    f = FooHistory.find(:first)
    c = Changeset.find_by_is_active(true)
    assert_equal f.changeset, c
  end
  # Test that changesets return list of changes
  def test_changeset_gets_changeables_list
    a = Foo.new
    a.save
    c = Changeset.find(:first)
    assert_not_nil c.changeables_list
    assert_equal 1, c.changeables_list.size
  end
  # Test that acts_as_changeable_history defaults to :same_as_changeable
  def test_default_changeable_history_same_as_changeable
    assert_equal Apple.changesetable_options, AppleHistory.changesetable_options
  end
  # Test that we don't have to list fields to track.
  def test_dont_need_field_options
    a = Apple.new
    a.color = 'red'
    a.size = 'small'
    a.save
    b = AppleHistory.find(:first)
    assert_not_nil b
    assert_equal a.color, b.color
    assert_equal a.size, b.size
    # Time objects get more precise than ActiveRecord can handle... maybe be off by up to half a second.
    assert_in_delta a.updated_at, b.updated_at, 1
  end
  
  # Test tracking of deleted_at paranoid objects - need to create a history when "deleted"
  def test_destroy_creates_a_history_if_tracking_deleted_at
    a = Foo.new
    a.save
    a.destroy
    assert_equal 2, FooHistory.find(:all).size
  end
  # Test that our database is getting cleaned after every test. (Necessary for the other tests to work)
  def test_clean_db
    assert_equal 0, Changeset.find(:all).size
    assert_equal 0, Foo.find(:all).size
    assert_equal 0, FooHistory.find(:all).size
  end
  # Test that the changeset has access to all of the changes.
  def test_changeset_can_find_changes
    a = Foo.new
    a.save
    assert_not_nil Changeset.find(:first).changes
    assert_equal 1, Changeset.active_changeset.changes.size
    c = Changeset.active_changeset.changes
    f = c["FooHistory"].first
    assert_equal a.id, f.foo_id
  end
end

