module ActsAsChangesetable #:nodoc:
  module Generator #:nodoc:
    module Commands #:nodoc:
     module Create
        def yaffle_route
          logger.route "map.yaffle"
          look_for = 'ActionController::Routing::Routes.draw do |map|'
          unless options[:pretend]
            gsub_file('config/routes.rb', /(#{Regexp.escape(look_for)})/mi){|match| "#{match}\n  map.yaffles\n"}
          end
        end
      end

      module Destroy
        def yaffle_route
          logger.route "map.yaffle"
          gsub_file 'config/routes.rb', /\n.+?map\.yaffles/mi, ''
        end
      end

      module List
        def yaffle_route
        end
      end

      module Update
        def yaffle_route
        end
      end
    end
  end
end

Rails::Generator::Commands::Create.send   :include,  ActsAsChangesetable::Generator::Commands::Create
Rails::Generator::Commands::Destroy.send  :include,  ActsAsChangesetable::Generator::Commands::Destroy
Rails::Generator::Commands::List.send     :include,  ActsAsChangesetable::Generator::Commands::List
Rails::Generator::Commands::Update.send   :include,  ActsAsChangesetable::Generator::Commands::Update