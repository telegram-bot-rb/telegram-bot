require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

require 'sdoc'
RDoc::Task.new(:doc) do |rdoc|
  rdoc.rdoc_dir = 'doc'

  rdoc.title = 'RailsStuff'

  rdoc.options << '--markup' << 'markdown'
  rdoc.options << '-e' << 'UTF-8'
  rdoc.options << '--format' << 'sdoc'
  rdoc.options << '--template' << 'rails'
  rdoc.options << '--all'

  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
