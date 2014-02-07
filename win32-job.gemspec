require 'rubygems'

Gem::Specification.new do |spec|
  spec.name      = 'win32-job'
  spec.version   = '0.1.2'
  spec.authors   = ['Daniel J. Berger', 'Park Heesob']
  spec.license   = 'Artistic 2.0'
  spec.email     = 'djberg96@gmail.com'
  spec.homepage  = 'http://github.com/djberg96/win32-job'
  spec.summary   = 'Interface for Windows jobs (process groups)'
  spec.test_file = 'test/test_win32_job.rb'
  spec.files     = Dir['**/*'].reject{ |f| f.include?('git') }

  spec.extra_rdoc_files  = ['README', 'CHANGES', 'MANIFEST']
  spec.rubyforge_project = 'win32utils'
  spec.required_ruby_version = '> 1.9.3'

  spec.add_dependency('ffi')

  spec.add_development_dependency('rake')
  spec.add_development_dependency('test-unit')

  spec.description = <<-EOF
    The win32-job library provides an interface for jobs (process groups)
    on MS Windows. This allows you to apply various limits and behavior to
    groups of processes on Windows.
  EOF
end
