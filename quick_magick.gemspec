require 'rubygems'
require 'date'

SPEC = Gem::Specification.new do |s|
	s.name = "quick_magick"
	s.version = "0.1.0"
	s.date = Date.today.to_s
	s.author = "Ahmed ElDawy"
	s.email = "ahmed.eldawy@badrit.com"
	s.homepage = "http://quickmagick.rubyforge.org/"
	s.platform = Gem::Platform::RUBY
	s.summary = "Access ImageMagick command line tools from Ruby."
	s.description = "QuickMagick allows you to access ImageMagick command line functions using Ruby interface."
	s.files = ["lib/quick_magick.rb", "lib/quick_magick/image.rb"]
	s.require_paths << "lib"
	s.test_file = "test/image_test.rb"
	s.rubyforge_project = "quickmagick"
	s.has_rdoc = true
	s.extra_rdoc_files = ["README"]
	s.requirements << 'ImageMagick properly installed with command line functions accessible'
end