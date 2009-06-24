class ActsAsChangesetableGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      # m.file "definition.txt", "definition.txt"
    end
  end
end