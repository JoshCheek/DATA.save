require_relative "lib/DATA.save"

Gem::Specification.new do |s|
  s.name        = "DATA.save"
  s.version     = DataSave::VERSION
  s.authors     = ["Josh Cheek"]
  s.email       = ["josh.cheek@gmail.com"]
  s.homepage    = "https://github.com/JoshCheek/DATA.save"
  s.summary     = %q{Store shit in your script's DATA segment}
  s.description = %q{Store shit in your script's DATA segment}
  s.license     = "WTFPL"

  s.rubyforge_project = "seeing_is_believing"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", "~> 3.2"
end
