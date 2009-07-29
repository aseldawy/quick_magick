require "tempfile"

module QuickMagick
  
  class Image
    class <<self
      
      # create an array of images from the given blob data
      def from_blob(blob, &proc)
        file = Tempfile.new(QuickMagick::random_string)
        file.write(blob)
        file.close
        self.read(file.path, &proc)
      end
      
      # create an array of images from the given file
      def read(filename, &proc)
        info = identify(%Q<"#{filename}">)
        if info.empty?
          raise QuickMagick::QuickMagickError, "Illegal file \"#{filename}\""
        end
        info_lines = info.split(/[\r\n]/)
        images = []
        if info_lines.size == 1
          images << Image.new(filename, info_lines.first)
        else
          info_lines.each_with_index do |info_line, i|
            images << Image.new("#{filename}[#{i.to_s}]", info_line)
          end
        end
        images.collect!(&proc)
        return images
      end
      
      alias open read
      
      def gradient(width, height, type=QuickMagick::LinearGradient, color1=nil, color2=nil)
        template_name = type + ":"
        template_name << color1.to_s if color1
        template_name << '-' << color2.to_s if color2
        i = self.new(template_name, nil, true)
        i.size = QuickMagick::Image::retrieve_geometry(width, height)
        i
      end
      
      # Creates an image with solid color
      def solid(width, height, color=nil)
        template_name = QuickMagick::SolidColor+":"
        template_name << color.to_s if color
        i = self.new(template_name, nil, true)
        i.size = QuickMagick::Image::retrieve_geometry(width, height)
        i
      end
      
      # Creates an image from pattern
      def pattern(width, height, pattern)
        raise QuickMagick::QuickMagickError, "Invalid pattern '#{pattern.to_s}'" unless QuickMagick::Patterns.include?(pattern.to_s)
        template_name = "pattern:#{pattern.to_s}"
        i = self.new(template_name, nil, true)
        i.size = QuickMagick::Image::retrieve_geometry(width, height)
        i
      end

      # returns info for an image using <code>identify</code> command
      def identify(filename)
        `identify #{filename}`
      end

      def retrieve_geometry(width, height=nil, x=nil, y=nil, flag=nil)
        geometry_string = ""
        geometry_string << width.to_s if width
        geometry_string << 'x' << height.to_s if height
        geometry_string << '+' << x.to_s if x
        geometry_string << '+' << y.to_s if y
        geometry_string << flag if flag
        geometry_string
      end
    end

    # append the given option, value pair to the args for the current image
    def append_to_operators(arg, value="")
      @operators << %Q<-#{arg} #{value}>
    end

    # append the given option, value pair to the settings of the current image
    def append_to_settings(arg, value="")
      @settings << %Q<-#{arg} #{value}>
    end

    IMAGE_SETTINGS_METHODS = %w{
      adjoin affine alpha antialias authenticate attenuate background bias black-point-compensation
      blue-primary bordercolor caption channel colors colorspace comment compose compress define
      delay depth display dispose dither encoding endian family fill filter font format fuzz gravity
      green-primary intent interlace interpolate interword-spacing kerning label limit loop mask
      mattecolor monitor orient ping pointsize preview quality quiet red-primary regard-warnings
      remap respect-parentheses scene seed stretch stroke strokewidth style taint texture treedepth
      transparent-color undercolor units verbose view virtual-pixel weight white-point

      density page sampling-factor size tile-offset
    }

    IMAGE_OPERATORS_METHODS = %w{
      alpha auto-orient bench black-threshold bordercolor charcoal clip clip-mask clip-path colorize
      contrast convolve cycle decipher deskew despeckle distort draw edge encipher emboss enhance equalize
      evaluate flip flop function gamma identify implode layers level level-colors median modulate monochrome
      negate noise normalize opaque ordered-dither NxN paint polaroid posterize print profile quantize
      radial-blur Raise random-threshold recolor render rotate segment sepia-tone set shade solarize
      sparse-color spread strip swirl threshold tile tint transform transparent transpose transverse trim
      type unique-colors white-threshold

      adaptive-blur adaptive-resize adaptive-sharpen annotate blur border chop contrast-stretch extent
      extract frame gaussian-blur geometry lat linear-stretch liquid-rescale motion-blur region repage
      resample resize roll sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast
      sketch splice thumbnail unsharp vignette wave
      
      append average clut coalesce combine composite deconstruct flatten fx hald-clut morph mosaic process reverse separate write
      crop
      }

    def floodfill(width, height=nil, x=nil, y=nil, flag=nil, color=nil)
      # TODO do a special method for floodfill
    end

    WITH_EQUAL_METHODS =
      %w{alpha antialias background bias black-point-compensation blue-primary border bordercolor caption
        cahnnel colors colorspace comment compose compress depth density encoding endian family fill filter
        font format frame fuzz geometry gravity label mattecolor page pointsize quality undercolor units weight
        brodercolor transparent type size}

    WITH_GEOMETRY_METHODS =
      %w{density page sampling-factor size tile-offset adaptive-blur adaptive-resize adaptive-sharpen
        annotate blur border chop contrast-stretch extent extract floodfill frame gaussian-blur
        geometry lat linear-stretch liquid-rescale motion-blur region repage resample resize roll
        sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast sketch
        splice thumbnail unsharp vignette wave crop}

    IMAGE_SETTINGS_METHODS.each do |method|
      if WITH_EQUAL_METHODS.include?(method)
        define_method((method+'=').to_sym) do |arg|
          append_to_settings(method, %Q<"#{arg}"> )
        end
      elsif WITH_GEOMETRY_METHODS.include?(method)
        define_method((method).to_sym) do |*args|
          append_to_settings(method, %Q<"#{QuickMagick::Image.retrieve_geometry(*args) }"> )
        end
      else
        define_method(method.to_sym) do |*args|
          append_to_settings(method, args.collect{|arg| %Q<"#{arg}"> }.join(" "))
        end
      end
    end
    
    IMAGE_OPERATORS_METHODS.each do |method|
      if WITH_EQUAL_METHODS.include?(method)
        define_method((method+'=').to_sym) do |arg|
          append_to_operators(method, %Q<"#{arg}"> )
        end
      elsif WITH_GEOMETRY_METHODS.include?(method)
        define_method((method).to_sym) do |*args|
          append_to_operators(method, %Q<"#{QuickMagick::Image.retrieve_geometry(*args) }"> )
        end
      else
        define_method(method.to_sym) do |*args|
          append_to_operators(method, args.collect{|arg| %Q<"#{arg}"> }.join(" "))
        end
      end
    end
    
    # define attribute readers (getters)
    attr_reader :image_filename
    alias original_filename image_filename
    
    # constructor
    def initialize(filename, info_line=nil, pseudo_image=false)
      @image_filename = filename
      @pseudo_image = pseudo_image
      if info_line
        @image_infoline = info_line.split
        @image_infoline[0..1] = @image_infoline[0..1].join(' ') while !@image_infoline[0].start_with?(image_filename)
      end
      @operators = ""
      @settings = ""
    end
    
    def command_line
      %Q<#{@settings} "#{image_filename}" #{@operators}>
    end
    
    def image_infoline
      unless @image_infoline
        @image_infoline = QuickMagick::Image::identify(command_line).split
        @image_infoline[0..1] = @image_infoline[0..1].join(' ') while !@image_infoline[0].start_with?(image_filename)
      end
      @image_infoline
    end

    # saves the current image to the given filename
    def save(output_filename)
      `convert #{command_line} "#{output_filename}"`
    end
    
    alias write save
    alias convert save
    
    # saves the current image overwriting the original image file
    def save!
      raise QuickMagick::QuickMagickError, "Cannot mogrify a pseudo image" if @pseudo_image
      `mogrify #{command_line}`
    end

    alias write! save!
    alias mogrify! save!

    def format
      image_infoline[1]
    end
    
    def columns
      image_infoline[2].split('x').first.to_i
    end
    
    alias width columns
    
    def rows
      image_infoline[2].split('x').last.to_i
    end
    
    alias height rows
    
    def bit_depth
      image_infoline[4].to_i
    end
    
    def colors
      image_infoline[6].to_i
    end
    
    def size
      File.size?(image_filename)
    end
    
    # displays the current image as animated image
    def animate
      `animate #{command_line}`
    end
    
    # displays the current image to the x-windowing system
    def display
      `display #{command_line}`
    end
  end
end