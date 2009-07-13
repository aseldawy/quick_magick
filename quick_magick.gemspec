require 'rubygems'
SPEC = Gem::Specification.new do |s|
	s.name = "quick_magick"
	s.version = "0.1.0"
	s.author = "Ahmed ElDawy"
	s.email = "ahmed.eldawy@badrit.com"
	s.homepage = "http://quickmagick.rubyforge.org/"
	s.platform = Gem::Platform::RUBY
	s.summary = "Access ImageMagick command line tools from Ruby"
	s.files = ["lib/quick_magick.rb", "lib/quick_magick/image.rb"]
	s.require_path = "lib"
	s.test_file = "test/image_test.rb"
	s.rubyforge_project = "quickmagick"
	s.has_rdoc = true
	s.extra_rdoc_files = ["README"]
end