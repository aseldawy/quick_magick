# check that ImageMagick is installed
status = `identify --version`
raise QuickMagick::QuickMagickError "ImageMagick not installed" if status.empty?
require 'quick_magick/image'

module QuickMagick
  class QuickMagickError < RuntimeError; end
  PercentGeometry = "%"
  AspectGeometry  = "!"
  LessGeometry = "<"
  GreaterGeometry = ">"
  AreaGeometry = "@"
  MinimumGeometry = "^"
  
  # generate a random string of specified length
  def self.random_string(length=10)
    @@CHARS ||= ("a".."z").to_a + ("1".."9").to_a 
    Array.new(length, '').collect{@@CHARS[rand(@@CHARS.size)]}.join
  end

end