ActiveRecord::Schema.define(:version => 0) do
  create_table :foos, :force => true do |t|
    t.string "field1"
    t.string "field2"
    t.string "field3"
    t.timestamps
  end
  create_table :foo_histories, :force => true do |t|
    t.integer "foo_id"
    t.string "field1"
    t.string "field2"
    t.string "field3"
    t.integer "changeset_id"
    t.timestamps
  end
  create_table :apples, :force => true do |t|
    t.string "color"
    t.string "size"
    t.timestamps
  end
  create_table :apple_histories, :force => true do |t|
    t.integer "apple_id"
    t.string "color"
    t.string "size"
    t.integer "changeset_id"
    t.timestamps
  end
  create_table :bar_histories, :force => true do |t|
  end
  create_table :changesets, :force => true do |t|
    t.timestamps
    t.boolean 'is_active'
  end
end