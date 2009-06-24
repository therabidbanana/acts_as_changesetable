require File.dirname(__FILE__) + '/test_helper.rb'
require 'rails_generator'
require 'rails_generator/scripts/generate'

class ActsAsChangeableGeneratorTest < Test::Unit::TestCase
  

  def setup
    FileUtils.mkdir_p(fake_rails_root)
    FileUtils.mkdir_p(config_path)
    @original_files = file_list
  end

  def teardown
    FileUtils.rm_r(fake_rails_root)
  end

  def test_no_files_created_on_incorrect_resource
    Rails::Generator::Scripts::Generate.new.run(%w(acts_as_changeable Foo), :destination => fake_rails_root)
    new_files = (file_list - @original_files)
    assert_equal 0, new_files.size
  end
  
  def test_generates_change_history_for_changeable
        file = <<-RUBY
    ActionController::Routing::Routes.draw do |map|
      map.connect ':controller/:action/:id'
      map.connect ':controller/:action/:id.:format'
    end
    RUBY
    File.open(routes_path, 'wb') {|f| f.write(file) }
    Rails::Generator::Scripts::Generate.new.run(%w(resource Foo bar:string baz:integer), :destination => fake_rails_root)
    Rails::Generator::Scripts::Generate.new.run(%w(acts_as_changeable Foo), :destination => fake_rails_root)
    new_files = (file_list - @original_files)
    filenames = new_files.map{|m| File.basename(m)}
    assert filenames.include?("app")
    assert controller_names.include?("foos_controller.rb")
    assert controller_names.include?("foo_histories_controller.rb")
    assert model_names.include?("foo_history.rb")
    assert model_names.include?("foo.rb")
    assert_match /acts_as_changeable/, File.read(File.join(fake_rails_root, 'app', 'models', 'foo.rb'))
    assert_match /acts_as_changeable_history/, File.read(File.join(fake_rails_root, 'app', 'models', 'foo_history.rb'))
    # assert_equal "definition.txt", File.basename(new_file)
  end

  private

    def fake_rails_root
      File.join(File.dirname(__FILE__), 'rails_root')
    end
    
    def config_path
      File.join(fake_rails_root, "config")
    end
    
    def routes_path
      File.join(config_path, "routes.rb")
    end
    
    def model_names
      Dir.glob(File.join(fake_rails_root, "app", "models", "*")).map{|file| File.basename(file)}
    end
    
    def models
      Dir.glob(File.join(fake_rails_root, "app", "models", "*"))
    end
    
    def controller_names
      Dir.glob(File.join(fake_rails_root, "app", "controllers", "*")).map{|file| File.basename(file)}
    end
    
    def controllers
      Dir.glob(File.join(fake_rails_root, "app", "controllers", "*"))
    end
    
    def file_list
      Dir.glob(File.join(fake_rails_root, "*"))
    end

end