require "tempfile"

module QuickMagick
  
  class Image
    class <<self
      
      # create an array of images from the given blob data
      def from_blob(blob)
        file = Tempfile.new(QuickMagick::random_string)
        file.write(blob)
        file.close
        self.read(file.path)
      end
      
      # create an array of images from the given file
      def read(filename, &proc)
        info = identify(filename)
        if info.empty?
          raise QuickMagick::QuickMagickError, "Illegal file #{filename}"
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
      
      # returns info for an image using <code>identify</code> command
      def identify(filename)
        `identify "#{filename}"`
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
    def append_to_args(arg, value="")
      args[arg] = value.to_s
    end
    
    # returns/creates the arguments for the current image
    def args
      @args ||= { }
    end
    
    def arg_string
      str = ""
      args.each do |k, v|
        str << "-#{k} #{v}"
      end
      str
    end
    
    # define methods to change options using methods of form option(args)
    OPTION_METHODS = 
    %w{authenticate attenuate monitor orient regard-warnings remap stretch stroke style colorize
      draw emboss enhance flip flop monochrome quantize rotate sepia-tone shade solarize spread
      strip tint transform transpose transverse trim unique-colors}
    OPTION_METHODS.each do |method|
      define_method(method.to_sym) do |*args|
        append_to_args(method, args.collect{|arg| %Q<"#{arg}">}.join)
      end
    end

    # define methods to change options using option=(args)
    OPTION_EQUAL_METHODS =
      %w{alpha antialias background bias black-point-compensation blue-primary border bordercolor caption
        cahnnel colors colorspace comment compose compress depth density encoding endian family fill filter
        font format frame fuzz geometry gravity label mattecolor page pointsize quality undercolor units weight
        brodercolor transparent type}
    OPTION_EQUAL_METHODS.each do |method|
      define_method((method+'=').to_sym) do |*args|
        append_to_args(method, args.collect{|arg| %Q<"#{arg}">}.join )
      end
    end
    
    # define methods that accepts a geometry parameter
    OPTION_GEOMETRY_METHODS =
      %w{density page sampling-factor size tile-offset adaptive-blur adaptive-resize adaptive-sharpen
        annotate blur border chop contrast-stretch extent extract floodfill frame gaussian-blur
        geometry lat linear-stretch liquid-rescale motion-blur region repage resample resize roll
        sample scale selective-blur shadow sharpen shave shear sigmoidal-contrast sketch
        splice thumbnail unsharp vignette wave crop}
    OPTION_GEOMETRY_METHODS.each do |method|
      define_method((method).to_sym) do |*args|
        append_to_args(method, %Q<"#{QuickMagick::Image.retrieve_geometry(*args)}"> )
      end
    end
    
    # define attribute readers (getters)
    attr_reader :image_filename, :image_infoline
    alias original_filename  image_filename
    
    # constructor
    def initialize(filename, info_line="")
      @image_filename = filename
      @image_infoline = info_line.split
      @image_infoline[0..1] = @image_infoline[0..1].join(' ') while @image_infoline[0] != filename
    end
    
    # saves the current image to the given filename
    def save(output_filename)
      `convert #{arg_string} "#{image_filename}" "#{output_filename}"`
    end
    
    alias write save
    alias convert save
    
    # saves the current image overwriting the original image file
    def save!
      `mogrify #{arg_string} "#{image_filename}"`
    end
    
    alias write! save!
    alias mogrify! save!
    
    def format
      @image_infoline[1]
    end
    
    def columns
      @image_infoline[2].split('x').first.to_i
    end
    
    alias width columns
    
    def rows
      @image_infoline[2].split('x').last.to_i
    end
    
    alias height rows
    
    def bit_depth
      @image_infoline[4].to_i
    end
    
    def colors
      @image_infoline[6].to_i
    end
    
    def size
      File.size?(image_filename)
    end
    
    # displays the current image as animated image
    def animate
      `animate #{image_filename}`
    end
    
    # displays the current image to the x-windowing system
    def display
      `display #{image_filename}`
    end
  end
end