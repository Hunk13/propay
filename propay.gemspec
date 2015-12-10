require File.expand_path('../lib/propay/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'propay'
  gem.authors     = ['Slava Kravchenko', 'Dima Berastau']
  gem.email       = ['slava.kravchenko@gmail.com', 'dima.berastau@gmail.com']
  gem.version     = ("$Release: #{ProPay::VERSION} $" =~ /[\.\d]+/) && $&
  gem.platform    = Gem::Platform::RUBY
  gem.homepage    = "https://github.com/karmasoft/propay"
  gem.summary     = "ProtectPay API"
  gem.description = <<HERE
ProtectPay API implementation.
HERE

  gem.files         = `git ls-files`.split($\) - ["Gemfile.lock"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency("nokogiri", "~> 1.5")
  gem.add_runtime_dependency("activemerchant", "~> 1.56")
  gem.add_development_dependency("rspec", "~> 2")

  gem.license = "MIT"
  gem.extra_rdoc_files = ["README.md", "ChangeLog"]
  gem.has_rdoc = false
end
