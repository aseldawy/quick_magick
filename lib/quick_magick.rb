# check if ImageMagick is installed
status = `identify --version`
raise QuickMagick::QuickMagickError("ImageMagick not installed") if status.empty?

module QuickMagick
  class QuickMagickError < RuntimeError; end
  PercentGeometry = "%"
  AspectGeometry  = "!"
  LessGeometry = "<"
  GreaterGeometry = ">"
  AreaGeometry = "@"
  MinimumGeometry = "^"
  
  SolidColor = "xc"
  LinearGradient = "gradient"
  RadialGradient = "radial-gradient"

  Patterns = %w{bricks checkboard circles crosshatch crosshatch30 crosshatch45 fishscales} +
    (0..20).collect {|level| "gray#{level}" } +
    %w{hexagons horizontal horizontalsaw hs_bdiagonal hs_cross hs_diagcross hs_fdiagonal hs_horizontal
    hs_vertical left30 left45 leftshingle octagons right30 right45 rightshingle smallfishscales
    vertical verticalbricks verticalleftshingle verticalrightshingle verticalsaw}
  
  # generate a random string of specified length
  def self.random_string(length=10)
    @@CHARS ||= ("a".."z").to_a + ("1".."9").to_a 
    Array.new(length, '').collect{@@CHARS[rand(@@CHARS.size)]}.join
  end
end

unless "".respond_to? :start_with?
  class String
    def start_with?(x)
      self.index(x) == 0
    end
  end
end

require 'quick_magick/image'
require 'quick_magick/image_list'