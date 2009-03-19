Gem::Specification.new do |s|
  s.name = %q{sweet_assets}
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jack Danger Canty"]
  s.date = %q{2009-03-19}
  s.description = %q{Automate adding stylesheets and javascripts to your controller actions}
  s.email = ["sweet_assets_gem@6brand.com"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "MIT-LICENSE", "Manifest.txt", "README.txt", "Rakefile", "init.rb", "install.rb", "lib/sweet_assets.rb", "rails/init.rb", "sweet_assets.gemspec", "test/sweet_assets_test.rb", "test/views/defaults/index.html.erb", "test/views/shortcut/index.html.erb", "test/views/web/index.html.erb", "uninstall.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/JackDanger/sweet_assets}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{objectproxy}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Automate adding stylesheets and javascripts to your controller actions}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.11.0"])
    else
      s.add_dependency(%q<hoe>, [">= 1.11.0"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.11.0"])
  end
end
