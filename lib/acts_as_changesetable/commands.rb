require 'rails_generator'
require 'rails_generator/commands'
module ActsAsChangesetable #:nodoc:
  module Generator #:nodoc:
    module Commands #:nodoc:
     module Create
        def acts_as_changeset
          puts "\tacts Changeset acts_as_changeset"
          look_for = "class Changeset < ActiveRecord::Base"
          unless options[:pretend]
            if(!File.read("app/models/changeset.rb").match(/acts_as_changeset/))
              gsub_file("app/models/changeset.rb", /(#{Regexp.escape(look_for)})/mi){|match| "#{match}\n  acts_as_changeset\n"}
            end
          end
        end
        def acts_as_changeable
          puts "\tacts #{class_name} acts_as_changeable"
          look_for = "class #{class_name} < ActiveRecord::Base"
          unless options[:pretend]
            if(!File.read("app/models/changeset.rb").match(/acts_as_changeable/))
              gsub_file("app/models/#{file_name}.rb", /(#{Regexp.escape(look_for)})/mi){|match| "#{match}\n  acts_as_changeable\n"}
            end
          end
        end
        def acts_as_changeable_history
          puts "\tacts #{class_name}History acts_as_changeable_history"
          look_for = "class #{class_name}History < ActiveRecord::Base"
          unless options[:pretend]
            if(!File.read("app/models/changeset.rb").match(/acts_as_changeable_history/))
              gsub_file("app/models/#{file_name}_history.rb", /(#{Regexp.escape(look_for)})/mi){|match| "#{match}\n  acts_as_changeable_history\n"}
            end
          end
        end
      end

      module Destroy
        def acts_as_changeable_history
          puts "\tacts #{class_name}History no longer acts_as_changeable_history"
          gsub_file "app/models/#{file_name}_history.rb", /\n.+?acts_as_changeable_history/mi, ''
        end
        def acts_as_changeable
          puts "\tacts #{class_name} no longer acts_as_changeable"
          gsub_file "app/models/#{file_name}.rb", /\n.+?acts_as_changeable/mi, ''
        end
        def acts_as_changeset
          puts "\tacts Changeset no longer acts_as_changeset"
          gsub_file "app/models/changeset.rb", /\n.+?acts_as_changeset/mi, ''
        end
      end

      module List
        def acts_as_changeable
        end
        def acts_as_changeable_history
        end
        def acts_as_changeset
        end
      end

      module Update
        def acts_as_changeable
        end
        def acts_as_changeable_history
        end
        def acts_as_changeset
        end
      end
    end
  end
end

Rails::Generator::Commands::Create.send   :include,  ActsAsChangesetable::Generator::Commands::Create
Rails::Generator::Commands::Destroy.send  :include,  ActsAsChangesetable::Generator::Commands::Destroy
Rails::Generator::Commands::List.send     :include,  ActsAsChangesetable::Generator::Commands::List
Rails::Generator::Commands::Update.send   :include,  ActsAsChangesetable::Generator::Commands::Update