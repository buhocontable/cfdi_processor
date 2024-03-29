
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cfdi_processor/version"

Gem::Specification.new do |spec|
  spec.name          = "cfdi_processor"
  spec.version       = CfdiProcessor::VERSION
  spec.authors       = ["Armando Alejandre"]
  spec.email         = ["armando1339@gmail.com"]

  spec.summary       = %q{Extracts the information from the cfdi and converts it into a hash}
  spec.description   = %q{Extracts the information from the cfdi and converts it into a hash}
  spec.homepage      = "https://buhocontable.com/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org/"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/armando1339/cfdi_processor"
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "nokogiri", "~> 1.6", ">= 1.6.8"
  spec.add_development_dependency "i18n", "~> 1.8", ">= 1.8.3"
  spec.add_development_dependency "bundler", "~> 2.2.4"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "shoulda-matchers", "~> 4.3"
  spec.add_development_dependency "pry", "~> 0.13.0"
end
