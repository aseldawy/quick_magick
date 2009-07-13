require "tempfile"

module QuickMagick
  class QuickMagickError < RuntimeError; end;
    
  class Image
    class <<self
      # generate a random string of specified length
      def random_string(length=10)
        @@CHARS ||= ("a".."z").to_a + ("1".."9").to_a 
        Array.new(length, '').collect{@@CHARS[rand(@@CHARS.size)]}.join
      end
      
      # create an array of images from the given blob data
      def from_blob(blob)
        file = Tempfile.new(random_string)
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
    end
    
    # append the given option, value pair to the args for the current image
    def append_to_args(arg, value="")
      args << "-#{arg.to_s} #{value.to_s} "
    end
    
    # returns/creates the arguments for the current image
    def args
      @args ||= ""
    end
    
    # define methods to change options using option
    %w{authenticate attenuate monitor orient regard-warnings remap
       sampling-factor size stretch stroke style
       chop colorize draw emboss enhance flip flop floodfill monochrome quantize resample resize
       rotate sample scale sepia-tone shade shadow sharpen shave shear sketch solarize
       splice spread strip thumbnail tint transform transpose transverse trim unique-colors
       unsharp}.each do |method|
      define_method(method.to_sym) do |*args|
        append_to_args(method, args[0])
      end
    end

    # define methods to change options using option=
    %w{alpha antialias background bias black-point-compensation blue-primary bordercolor caption
       cahnnel colors colorspace comment compose compress density depth encoding endian family fill
       filter font format fuzz gravity label mattecolor page pointsize quality undercolor units weight
       border brodercolor frame geometry transparent type}.each do |method|
      define_method((method+'=').to_sym) do |*args|
        append_to_args(method, args[0])
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
      `convert #{args} "#{image_filename}" "#{output_filename}"`
    end
    
    alias write save
    alias convert save
    
    # saves the current image overwriting the original image file
    def save!
      `mogrify #{args} "#{image_filename}"`
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