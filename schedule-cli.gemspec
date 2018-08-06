# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schedule/version'

Gem::Specification.new do |spec|
  spec.name          = 'schedule-cli'
  spec.version       = Schedule::VERSION
  spec.authors       = ['Yasyf Mohamedali']
  spec.email         = ['yasyf@meetkaruna.com']

  spec.summary       = 'CLI to generare summary of calendar openings.'
  spec.homepage      = 'https://github.com/karuna-health/schedule-cli'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_dependency 'activesupport', '~> 5.2'
  spec.add_dependency 'chronic'
  spec.add_dependency 'google-api-client', '~> 0.11'
  spec.add_dependency 'launchy'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'parallel'
  spec.add_dependency 'thor'
end
