require "tempfile"

module QuickMagick
  
  class Image
    class << self
      
      # create an array of images from the given blob data
      def from_blob(blob, &proc)
        file = Tempfile.new(QuickMagick::random_string)
        file.binmode
        file.write(blob)
        file.close
        self.read(file.path, &proc)
      end
      
      # create an array of images from the given file
      def read(filename, &proc)
        info = identify(%Q<"#{filename}">)
        info_lines = info.split(/[\r\n]/)
        images = []
        info_lines.each_with_index do |info_line, i|
          images << Image.new("#{filename}", i, info_line)
        end
        images.each(&proc) if block_given?
        return images
      end
      
      alias open read
      
      # Creates a new image initially set to gradient
      # Default gradient is linear gradient from black to white
      def gradient(width, height, type=QuickMagick::LinearGradient, color1=nil, color2=nil)
        template_name = type + ":"
        template_name << color1.to_s if color1
        template_name << '-' << color2.to_s if color2
        i = self.new(template_name, 0, nil, true)
        i.size = QuickMagick::geometry(width, height)
        i
      end
      
      # Creates an image with solid color
      def solid(width, height, color=nil)
        template_name = QuickMagick::SolidColor+":"
        template_name << color.to_s if color
        i = self.new(template_name, 0, nil, true)
        i.size = QuickMagick::geometry(width, height)
        i
      end
      
      # Creates an image from pattern
      def pattern(width, height, pattern)
        raise QuickMagick::QuickMagickError, "Invalid pattern '#{pattern.to_s}'" unless QuickMagick::Patterns.include?(pattern.to_s)
        template_name = "pattern:#{pattern.to_s}"
        i = self.new(template_name, 0, nil, true)
        i.size = QuickMagick::geometry(width, height)
        i
      end

      # returns info for an image using <code>identify</code> command
      def identify(filename)
	    	error_file = Tempfile.new('identify_error')
        result = `identify #{filename} 2>'#{error_file.path}'`
        unless $?.success?
		      error_message = <<-ERROR
		        Error executing command: identify #{filename}
		        Result is: #{result}
		        Error is: #{error_file.read}
		      ERROR
          raise QuickMagick::QuickMagickError, error_message
        end
        result
      ensure
      	error_file.close
      end

    end

    # append the given option, value pair to the settings of the current image
    def append_to_settings(arg, value=nil)
      @arguments << %Q<-#{arg} #{QuickMagick::c value} >
      @last_is_draw = false
      self
    end
    
    # append the given string as is. Used to append special arguments like +antialias or +debug
    def append_basic(arg)
      @arguments << arg << ' '
    end

    # Image settings supported by ImageMagick
    IMAGE_SETTINGS_METHODS = %w{
      adjoin affine alpha authenticate attenuate background bias black-point-compensation
      blue-primary bordercolor caption channel colors colorspace comment compose compress define
      delay depth display dispose dither encoding endian family fill filter font format fuzz gravity
      green-primary intent interlace interpolate interword-spacing kerning label limit loop mask
      mattecolor monitor orient ping pointsize preview quality quiet red-primary regard-warnings
      remap respect-parentheses scene seed stretch stroke strokewidth style taint texture treedepth
      transparent-color undercolor units verbose view virtual-pixel weight white-point

      density page sampling-factor size tile-offset
    }

    # append the given option, value pair to the args for the current image
    def append_to_operators(arg, value=nil)
      is_draw = (arg == 'draw')
      if @last_is_draw && is_draw
        @arguments.insert(@arguments.rindex('"'), " #{value}")
      else
        @arguments << %Q<-#{arg} #{QuickMagick::c value} >
      end
      @last_is_draw = is_draw
      self
    end
    
    # Reverts this image to its last saved state.
    # Note that you cannot revert an image created from scratch.
    def revert!
      raise QuickMagick::QuickMagickError, "Cannot revert a pseudo image" if @pseudo_image
      @arguments = ""
    end

    # Image operators supported by ImageMagick
    IMAGE_OPERATORS_METHODS = %w{
      alpha auto-orient bench black-threshold bordercolor charcoal clip clip-mask clip-path colorize
      contrast convolve cycle decipher deskew despeckle distort edge encipher emboss enhance equalize
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

    # methods that are called with (=)
    WITH_EQUAL_METHODS =
      %w{alpha background bias black-point-compensation blue-primary border bordercolor caption
        cahnnel colors colorspace comment compose compress depth density encoding endian family fill filter
        font format frame fuzz geometry gravity label mattecolor page pointsize quality stroke strokewidth
        undercolor units weight
        brodercolor transparent type size}

    # methods that takes geometry options
    WITH_GEOMETRY_METHODS =
      %w{density page sampling-factor size tile-offset adaptive-blur adaptive-resize adaptive-sharpen
        annotate blur border chop contrast-stretch extent extract frame gaussian-blur
        geometry lat linear-stretch liquid-rescale motion-blur region repage resample resize roll
        sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast sketch
        splice thumbnail unsharp vignette wave crop}
   
    # Methods that need special treatment. This array is used just to keep track of them.
    SPECIAL_COMMANDS =
      %w{floodfill antialias draw}

    IMAGE_SETTINGS_METHODS.each do |method|
      if WITH_EQUAL_METHODS.include?(method)
        define_method((method+'=').to_sym) do |arg|
          append_to_settings(method, arg)
        end
      elsif WITH_GEOMETRY_METHODS.include?(method)
        define_method((method).to_sym) do |*args|
          append_to_settings(method, QuickMagick::geometry(*args) )
        end
      else
        define_method(method.to_sym) do |*args|
          append_to_settings(method, args.join(" "))
        end
      end
    end
    
    IMAGE_OPERATORS_METHODS.each do |method|
      if WITH_EQUAL_METHODS.include?(method)
        define_method((method+'=').to_sym) do |arg|
          append_to_operators(method, arg )
        end
      elsif WITH_GEOMETRY_METHODS.include?(method)
        define_method((method).to_sym) do |*args|
          append_to_operators(method, QuickMagick::geometry(*args) )
        end
      else
        define_method(method.to_sym) do |*args|
          append_to_operators(method, args.join(" "))
        end
      end
    end

    # Fills a rectangle with a solid color
    def floodfill(width, height=nil, x=nil, y=nil, flag=nil, color=nil)
      append_to_operators "floodfill", QuickMagick::geometry(width, height, x, y, flag), color
    end
    
    # Enables/Disables flood fill. Pass a boolean argument.
    def antialias=(flag)
    	append_basic flag ? '-antialias' : '+antialias'
    end
    
    # define attribute readers (getters)
    attr_reader :image_filename
    alias original_filename image_filename
    
    # constructor
    def initialize(filename, index=0, info_line=nil, pseudo_image=false)
      @image_filename = filename
      @index = index
      @pseudo_image = pseudo_image
      if info_line
        @image_infoline = info_line.split
        @image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline.size > 1 && !@image_infoline[0].start_with?(image_filename)
      end
      @arguments = ""
    end
    
    # The command line so far that will be used to convert or save the image
    def command_line
      %Q< "(" #{@arguments} #{QuickMagick::c(image_filename + (@pseudo_image ? "" : "[#{@index}]"))} ")" >
    end
    
    # An information line about the image obtained using 'identify' command line
    def image_infoline
      return nil if @pseudo_image
      unless @image_infoline
        @image_infoline = QuickMagick::Image::identify(command_line).split
        @image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline.size > 1 && !@image_infoline[0].start_with?(image_filename)
      end
      @image_infoline
    end

    # converts options passed to any primitive to a string that can be passed to ImageMagick
    # options allowed are:
    # * rotate          degrees
    # * translate       dx,dy
    # * scale           sx,sy
    # * skewX           degrees
    # * skewY           degrees
    # * gravity         NorthWest, North, NorthEast, West, Center, East, SouthWest, South, or SouthEast
    # * stroke          color
    # * fill            color
    # The rotate primitive rotates subsequent shape primitives and text primitives about the origin of the main image.
    # If you set the region before the draw command, the origin for transformations is the upper left corner of the region.
    # The translate primitive translates subsequent shape and text primitives.
    # The scale primitive scales them.
    # The skewX and skewY primitives skew them with respect to the origin of the main image or the region.
    # The text gravity primitive only affects the placement of text and does not interact with the other primitives.
    # It is equivalent to using the gravity method, except that it is limited in scope to the draw_text option in which it appears.
    def options_to_str(options)
      options.to_a.flatten.join " "
    end

    # Converts an array of coordinates to a string that can be passed to polygon, polyline and bezier
    def points_to_str(points)
      raise QuickMagick::QuickMagickError, "Points must be an even number of coordinates" if points.size.odd?
      points_str = ""
      points.each_slice(2) do |point|
        points_str << point.join(",") << " "
      end
      points_str
    end

    # The shape primitives are drawn in the color specified by the preceding -fill setting.
    # For unfilled shapes, use -fill none.
    # You can optionally control the stroke (the "outline" of a shape) with the -stroke and -strokewidth settings.
    
    # draws a point at the given location in pixels
    # A point primitive is specified by a single point in the pixel plane, that is, by an ordered pair
    # of integer coordinates, x,y.
    # (As it involves only a single pixel, a point primitive is not affected by -stroke or -strokewidth.)
    def draw_point(x, y, options={})
      append_to_operators("draw", "#{options_to_str(options)} point #{x},#{y}")
    end
    
    # draws a line between the given two points
    # A line primitive requires a start point and end point.
    def draw_line(x0, y0, x1, y1, options={})
      append_to_operators("draw", "#{options_to_str(options)} line #{x0},#{y0} #{x1},#{y1}")
    end
    
    # draw a rectangle with the given two corners
    # A rectangle primitive is specified by the pair of points at the upper left and lower right corners.
    def draw_rectangle(x0, y0, x1, y1, options={})
      append_to_operators("draw", "#{options_to_str(options)} rectangle #{x0},#{y0} #{x1},#{y1}")
    end

    # draw a rounded rectangle with the given two corners
    # wc and hc are the width and height of the arc
    # A roundRectangle primitive takes the same corner points as a rectangle
    # followed by the width and height of the rounded corners to be removed.
    def draw_round_rectangle(x0, y0, x1, y1, wc, hc, options={})
      append_to_operators("draw", "#{options_to_str(options)} roundRectangle #{x0},#{y0} #{x1},#{y1} #{wc},#{hc}")
    end
    
    # The arc primitive is used to inscribe an elliptical segment in to a given rectangle.
    # An arc requires the two corners used for rectangle (see above) followed by
    # the start and end angles of the arc of the segment segment (e.g. 130,30 200,100 45,90).
    # The start and end points produced are then joined with a line segment and the resulting segment of an ellipse is filled.
    def draw_arc(x0, y0, x1, y1, a0, a1, options={})
      append_to_operators("draw", "#{options_to_str(options)} arc #{x0},#{y0} #{x1},#{y1} #{a0},#{a1}")
    end

    # Use ellipse to draw a partial (or whole) ellipse.
    # Give the center point, the horizontal and vertical "radii"
    # (the semi-axes of the ellipse) and start and end angles in degrees (e.g. 100,100 100,150 0,360).
    def draw_ellipse(x0, y0, rx, ry, a0, a1, options={})
      append_to_operators("draw", "#{options_to_str(options)} ellipse #{x0},#{y0} #{rx},#{ry} #{a0},#{a1}")
    end
    
    # The circle primitive makes a disk (filled) or circle (unfilled). Give the center and any point on the perimeter (boundary).
    def draw_circle(x0, y0, x1, y1, options={})
      append_to_operators("draw", "#{options_to_str(options)} circle #{x0},#{y0} #{x1},#{y1}")
    end
    
    # The polyline primitive requires three or more points to define their perimeters.
    # A polyline is simply a polygon in which the final point is not stroked to the start point.
    # When unfilled, this is a polygonal line. If the -stroke setting is none (the default), then a polyline is identical to a polygon.
    #  points - A single array with each pair forming a coordinate in the form (x, y).
    # e.g. [0,0,100,100,100,0] will draw a polyline between points (0,0)-(100,100)-(100,0)
    def draw_polyline(points, options={})
      append_to_operators("draw", "#{options_to_str(options)} polyline #{points_to_str(points)}")
    end

    # The polygon primitive requires three or more points to define their perimeters.
    # A polyline is simply a polygon in which the final point is not stroked to the start point.
    # When unfilled, this is a polygonal line. If the -stroke setting is none (the default), then a polyline is identical to a polygon.
    #  points - A single array with each pair forming a coordinate in the form (x, y). 
    # e.g. [0,0,100,100,100,0] will draw a polygon between points (0,0)-(100,100)-(100,0)
    def draw_polygon(points, options={})
      append_to_operators("draw", "#{options_to_str(options)} polygon #{points_to_str(points)}")
    end

    # The Bezier primitive creates a spline curve and requires three or points to define its shape.
    # The first and last points are the knots and these points are attained by the curve,
    # while any intermediate coordinates are control points.
    # If two control points are specified, the line between each end knot and its sequentially
    # respective control point determines the tangent direction of the curve at that end.
    # If one control point is specified, the lines from the end knots to the one control point
    # determines the tangent directions of the curve at each end.
    # If more than two control points are specified, then the additional control points
    # act in combination to determine the intermediate shape of the curve.
    # In order to draw complex curves, it is highly recommended either to use the path primitive
    # or to draw multiple four-point bezier segments with the start and end knots of each successive segment repeated.
    def draw_bezier(points, options={})
      append_to_operators("draw", "#{options_to_str(options)} bezier #{points_to_str(points)}")
    end
    
    # A path represents an outline of an object, defined in terms of moveto
    # (set a new current point), lineto (draw a straight line), curveto (draw a Bezier curve),
    # arc (elliptical or circular arc) and closepath (close the current shape by drawing a
    # line to the last moveto) elements.
    # Compound paths (i.e., a path with subpaths, each consisting of a single moveto followed by
    # one or more line or curve operations) are possible to allow effects such as donut holes in objects.
    # (See http://www.w3.org/TR/SVG/paths.html)
    def draw_path(path_spec, options={})
      append_to_operators("draw", "#{options_to_str(options)} path #{path_spec}")
    end
    
    # Use image to composite an image with another image. Follow the image keyword
    # with the composite operator, image location, image size, and filename
    # You can use 0,0 for the image size, which means to use the actual dimensions found in the image header.
    # Otherwise, it is scaled to the given dimensions. See -compose for a description of the composite operators.
    def draw_image(operator, x0, y0, w, h, image_filename, options={})
      append_to_operators("draw", "#{options_to_str(options)} image #{operator} #{x0},#{y0} #{w},#{h} \"#{image_filename}\"")
    end
    
    # Use text to annotate an image with text. Follow the text coordinates with a string.
    def draw_text(x0, y0, text, options={})
      append_to_operators("draw", "#{options_to_str(options)} text #{x0},#{y0} '#{text}'")
    end
    
    # saves the current image to the given filename
    def save(output_filename)
    	error_file = Tempfile.new('convert_error')
      result = `convert #{command_line} '#{output_filename}' 2>'#{error_file.path}'`
      if $?.success?
      	if @pseudo_image
      		# since it's been saved, convert it to normal image (not pseudo)
      		initialize(output_filename)
		    	revert!
      	end
        return result 
      else
        error_message = <<-ERROR
          Error executing command: convert #{command_line} "#{output_filename}"
          Result is: #{result}
          Error is: #{error_file.read}
        ERROR
        raise QuickMagick::QuickMagickError, error_message
      end
    ensure
    	error_file.close
    end
    
    alias write save
    alias convert save
    
    # saves the current image overwriting the original image file
    def save!
      raise QuickMagick::QuickMagickError, "Cannot mogrify a pseudo image" if @pseudo_image
     	error_file = Tempfile.new('mogrify_error')
      result = `mogrify #{command_line} 2>'#{error_file.path}'`
      if $?.success?
        # remove all operations to avoid duplicate operations
        revert!
        return result 
      else
        error_message = <<-ERRORMSG
          Error executing command: mogrify #{command_line}
          Result is: #{result}
          Error is: #{error_file.read}
        ERRORMSG
        raise QuickMagick::QuickMagickError, error_message
      end
    ensure
    	error_file.close if error_file
    end

    alias write! save!
    alias mogrify! save!
    
    def to_blob
    	tmp_file = Tempfile.new(QuickMagick::random_string)
    	if command_line =~ /-format\s(\S+)\s/
    		# use format set up by user
    		blob_format = $1
    	elsif !@pseudo_image
    		# use original image format
    		blob_format = self.format
    	else
		  	# default format is jpg
		  	blob_format = 'jpg'
    	end
    	save "#{blob_format}:#{tmp_file.path}"
    	blob = nil
    	File.open(tmp_file.path, 'rb') { |f| blob = f.read}
    	blob
    end

    # image file format
    def format
      image_infoline[1]
    end
    
    # columns of image in pixels
    def columns
      image_infoline[2].split('x').first.to_i
    end
    
    alias width columns
    
    # rows of image in pixels
    def rows
      image_infoline[2].split('x').last.to_i
    end
    
    alias height rows
    
    # Bit depth
    def bit_depth
      image_infoline[4].to_i
    end
    
    # Number of different colors used in this image
    def colors
      image_infoline[6].to_i
    end
    
    # returns size of image in bytes
    def size
      File.size?(image_filename)
    end
    
    # Reads a pixel from the image.
    # WARNING: This is done through command line which is very slow.
    # It is not recommended at all to use this method for image processing for example.
    def get_pixel(x, y)
    	error_file = Tempfile.new('identify_error')
      result = `identify -verbose -crop #{QuickMagick::geometry(1,1,x,y)} #{QuickMagick::c(image_filename)}[#{@index}]  2>'#{error_file.path}'`
      unless $?.success?
	      error_message = <<-ERROR
	        Error executing command: identify #{image_filename}
	        Result is: #{result}
	        Error is: #{error_file.read}
	      ERROR
        raise QuickMagick::QuickMagickError, error_message
      end
      result =~ /Histogram:\s*\d+:\s*\(\s*(\d+),\s*(\d+),\s*(\d+)\)/
      return [$1.to_i, $2.to_i, $3.to_i]
    ensure
    	error_file.close
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
