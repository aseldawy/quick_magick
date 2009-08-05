# Define quick magick error
module QuickMagick
  class QuickMagickError < RuntimeError; end
end

# check if ImageMagick is installed
begin
  x = `identify --version 2>&1`
  raise(QuickMagick::QuickMagickError, "ImageMagick not installed") unless x.index('ImageMagick') 
rescue Errno::ENOENT
  # For Windows machines
  raise(QuickMagick::QuickMagickError, "ImageMagick not installed")
end

module QuickMagick
  # Different geometry flags
  PercentGeometry = "%"
  AspectGeometry  = "!"
  LessGeometry = "<"
  GreaterGeometry = ">"
  AreaGeometry = "@"
  MinimumGeometry = "^"
  
  # Command for solid color
  SolidColor = "xc"
  # Command for linear gradient
  LinearGradient = "gradient"
  # Command for radial gradient
  RadialGradient = "radial-gradient"

  # Different possible patterns
  Patterns = %w{bricks checkboard circles crosshatch crosshatch30 crosshatch45 fishscales} +
    (0..20).collect {|level| "gray#{level}" } +
    %w{hexagons horizontal horizontalsaw hs_bdiagonal hs_cross hs_diagcross hs_fdiagonal hs_horizontal
    hs_vertical left30 left45 leftshingle octagons right30 right45 rightshingle smallfishscales
    vertical verticalbricks verticalleftshingle verticalrightshingle verticalsaw}
  
  # Generate a random string of specified length.
  # Used to generate random names for temp files
  def self.random_string(length=10)
    @@CHARS ||= ("a".."z").to_a + ("1".."9").to_a 
    Array.new(length, '').collect{@@CHARS[rand(@@CHARS.size)]}.join
  end
end

# For backward compatibility with ruby < 1.8.7
unless "".respond_to? :start_with?
  class String
    def start_with?(x)
      self.index(x) == 0
    end
  end
end

require 'quick_magick/image'
require 'quick_magick/image_list'