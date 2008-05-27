(in /www/projects/sweet_assets)
Gem::Specification.new do |s|
  s.name = %q{sweet_assets}
  s.version = "2.0.1"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jack Danger Canty"]
  s.date = %q{2008-05-26}
  s.description = %q{}
  s.email = ["sweet_assets_gem@6brand.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "MIT-LICENSE", "Manifest.txt", "README.txt", "Rakefile", "init.rb", "install.rb", "lib/sweet_assets.rb", "test/sweet_assets_test.rb", "test/views/defaults/index.html.erb", "test/views/shortcut/index.html.erb", "test/views/web/index.html.erb", "uninstall.rb"]
  s.has_rdoc = true
  s.homepage = %q{  Automate adding stylesheets and javascripts to your controller actions}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{objectproxy}
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{}

  s.add_dependency(%q<hoe>, [">= 1.5.1"])
end
