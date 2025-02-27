require 'rubygems'

Gem::Specification.new do |spec|
  spec.name       = 'sys-cpu'
  spec.version    = '1.0.3'
  spec.author     = 'Daniel J. Berger'
  spec.email      = 'djberg96@gmail.com'
  spec.license    = 'Apache-2.0'
  spec.homepage   = 'https://github.com/djberg96/sys-cpu'
  spec.summary    = 'A Ruby interface for providing CPU information'
  spec.test_files = Dir['spec/*.rb']
  spec.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  spec.cert_chain = ['certs/djberg96_pub.pem']

  spec.extra_rdoc_files = Dir['*.rdoc']

  # The ffi dependency is only relevent for the Unix version. Given the
  # ubiquity of ffi these days, I felt a bogus dependency on ffi for Windows
  # and Linux was worth the tradeoff of not having to create 3 separate gems.
  spec.add_dependency('ffi', '~> 1.1')

  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec', '~> 3.9')

  spec.metadata = {
    'homepage_uri'      => 'https://github.com/djberg96/sys-cpu',
    'bug_tracker_uri'   => 'https://github.com/djberg96/sys-cpu/issues',
    'changelog_uri'     => 'https://github.com/djberg96/sys-cpu/blob/ffi/CHANGES.md',
    'documentation_uri' => 'https://github.com/djberg96/sys-cpu/wiki',
    'source_code_uri'   => 'https://github.com/djberg96/sys-cpu',
    'wiki_uri'          => 'https://github.com/djberg96/sys-cpu/wiki'
  }

  spec.description = <<-EOF
    The sys-cpu library provides an interface for gathering information
    about your system's processor(s). Information includes speed, type,
    and load average.
  EOF
end
