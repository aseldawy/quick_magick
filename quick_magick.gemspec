# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{quick_magick}
  s.version = "0.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ahmed ElDawy"]
  s.date = %q{2010-01-30}
  s.description = %q{QuickMagick allows you to access ImageMagick command line functions using Ruby interface.}
  s.email = %q{ahmed.eldawy@badrit.com}
  s.extra_rdoc_files = ["README.rdoc", "lib/quick_magick.rb", "lib/quick_magick/image.rb", "lib/quick_magick/image_list.rb"]
  s.files = ["Manifest", "README.rdoc", "Rakefile", "lib/quick_magick.rb", "lib/quick_magick/image.rb", "lib/quick_magick/image_list.rb", "test/9.gif", "test/badfile.xxx", "test/image_list_test.rb", "test/image_test.rb", "test/multipage.tif", "test/test_magick.rb", "test/warnings.tiff", "quick_magick.gemspec"]
  s.homepage = %q{http://quickmagick.rubyforge.org/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Quick_magick", "--main", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{quickmagick}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{QuickMagick allows you to access ImageMagick command line functions using Ruby interface.}
  s.test_files = ["test/image_test.rb", "test/image_list_test.rb", "test/test_magick.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
