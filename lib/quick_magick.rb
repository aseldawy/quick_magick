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
  # Normally the attributes are treated as pixels.
  # Use this flag when the width and height attributes represent percentages.
  # For example, 125x75 means 125% of the height and 75% of the width.
  # The x and y attributes are not affected by this flag.  
  PercentGeometry = "%"
  
  # Use this flag when you want to force the new image to have exactly the size specified by the the width and height attributes.
  AspectGeometry  = "!"
  
  # Use this flag when you want to change the size of the image only if both its width and height
  # are smaller the values specified by those attributes. The image size is changed proportionally.
  LessGeometry = "<"
  
  # Use this flag when you want to change the size of the image if either its width and height
  # exceed the values specified by those attributes. The image size is changed proportionally.
  GreaterGeometry = ">"
  
  # This flag is useful only with a single width attribute.
  # When present, it means the width attribute represents the total area of the image in pixels.
  AreaGeometry = "@"
  
  # Use ^ to set a minimum image size limit.
  # The geometry 640x480^, for example, means the image width will not be less than 640 and
  # the image height will not be less than 480 pixels after the resize.
  # One of those dimensions will match the requested size,
  # but the image will likely overflow the space requested to preserve its aspect ratio.
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
  
  
  class <<self
    # Generate a random string of specified length.
    # Used to generate random names for temp files
    def random_string(length=10)
      @@CHARS ||= ("a".."z").to_a + ("1".."9").to_a 
      Array.new(length, '').collect{@@CHARS[rand(@@CHARS.size)]}.join
    end
    
    # Encodes a geometry string with the given options
    def geometry(width, height=nil, x=nil, y=nil, flag=nil)
      geometry_string = ""
      geometry_string << width.to_s if width
      geometry_string << 'x' << height.to_s if height
      geometry_string << '+' << x.to_s if x
      geometry_string << '+' << y.to_s if y
      geometry_string << flag if flag
      geometry_string
    end
    
    # Returns a formatted string for the color with the given components
    # each component could take one of the following values
    # * an integer from 0 to 255
    # * a float from 0.0 to 1.0
    # * a string showing percentage from "0%" to "100%"
    def rgba_color(red, green, blue, alpha=255)
      "#%02x%02x%02x%02x" % [red, green, blue, alpha].collect do |component|
        case component
          when Integer then component
          when Float then Integer(component*255)
          when String then Integer(component.sub('%', '')) * 255 / 100
        end
      end
    end
    
    alias rgb_color rgba_color
    
    # Returns a formatted string for a gray color with the given level and alpha.
    # level and alpha could take one of the following values
    # * an integer from 0 to 255
    # * a float from 0.0 to 1.0
    # * a string showing percentage from "0%" to "100%"
    def graya_color(level, alpha=255)
      rgba_color(level, level, level, alpha)
    end
    
    alias gray_color graya_color
    
    # HSL colors are encoding as a triple (hue, saturation, lightness).
    # Hue is represented as an angle of the color circle (i.e. the rainbow represented in a circle).
    # This angle is so typically measured in degrees that the unit is implicit in CSS;
    # syntactically, only a number is given. By definition red=0=360,
    # and the other colors are spread around the circle, so green=120, blue=240, etc.
    # As an angle, it implicitly wraps around such that -120=240 and 480=120, for instance.
    # (Students of trigonometry would say that "coterminal angles are equivalent" here;
    # an angle (theta) can be standardized by computing the equivalent angle, (theta) mod 360.)
    #
    # Saturation and lightness are represented as percentages.
    # 100% is full saturation, and 0% is a shade of grey.
    # 0% lightness is black, 100% lightness is white, and 50% lightness is 'normal'.
    #
    # Hue can take one of the following values:
    # * an integer from 0...360 representing angle in degrees
    # * a float value from 0...2*PI represeting angle in radians
    #
    # saturation, lightness and alpha can take one of the following values:
    # * an integer from 0 to 255
    # * a float from 0.0 to 1.0
    # * a string showing percentage from "0%" to "100%"
    def hsla_color(hue, saturation, lightness, alpha=1.0)
      components = [case hue
        when Integer then hue
        when Float then Integer(hue * 360 / 2 / Math::PI)
      end]
      components += [saturation, lightness].collect do |component|
        case component
          when Integer then (component * 100.0 / 255).round
          when Float then Integer(component*100)
          when String then Integer(component.sub('%', ''))
        end
      end
      components << case alpha
        when Integer then alpha * 100.0 / 255
        when Float then alpha
        when String then Float(alpha.sub('%', '')) / 100.0
      end
      "hsla(%d,%d%%,%d%%,%g)" % components
    end
    
    alias hsl_color hsla_color
    
    # Escapes possible special chracters in command line by surrounding it with double quotes
    def escape_commandline(str)
      str =~ /^(\w|\s|\.)*$/ ? str : "\"#{str}\""
    end
    
    alias c escape_commandline
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

unless "".respond_to? :end_with?
  class String
    def end_with?(x)
      self.index(x) == self.length - 1
    end
  end
end

require 'quick_magick/image'
require 'quick_magick/image_list'