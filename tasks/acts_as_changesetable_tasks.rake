PKG_FILES = FileList[
  '[a-zA-Z]*',
  'generators/**/*',
  'lib/**/*',
  'rails/**/*',
  'tasks/**/*',
  'test/**/*'
]

spec = Gem::Specification.new do |s|
  s.name = "acts_as_changesetable"
  s.version = "0.0.7"
  s.author = "David Haslem"
  s.email = "therabidbanana@gmail.com"
  s.homepage = "http://www.google.com/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Allows models to track changes in changesets"
  s.files = PKG_FILES.to_a
  s.require_path = "lib"
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
end

desc 'Turn this plugin into a gem.'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end