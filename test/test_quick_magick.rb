require 'test/unit'
require 'quick_magick'

$base_dir = File.dirname(File.expand_path(__FILE__))

class QuickMagickTest < Test::Unit::TestCase
  def test_escape_commandline
    [
      ["good_file_name.png", "good_file_name.png"],
      ["filename with spaces.png", '"filename with spaces.png"'],
      ["filename_with_$pec!als.jpg", '"filename_with_$pec!als.jpg"']
    ].each do |filename, escaped_filename|
      assert_equal escaped_filename, QuickMagick::c(filename)
    end
    
  end
end
