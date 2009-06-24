class ActsAsChangesetGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.dependency("resource", %w(Changeset is_active:boolean), options) unless defined? Changeset
      m.acts_as_changeset
    end
  end

end