module QuickMagick
  class ImageList

    def initialize(*filenames)
      @images = filenames.inject([]) do |image_list, filename|
        image_list + QuickMagick::Image.read(filename)
      end
    end

    # Delegate Array methods
    Array.public_instance_methods(false).each do |array_public_method|
      class_eval do
        define_method array_public_method do |*args|
          @images.send array_public_method, *args
        end
      end
    end
      
    # Delegate Image methods
    QuickMagick::Image.public_instance_methods(false).each do |image_public_method|
      class_eval do
        define_method image_public_method do |*args|
          @images.each do |image|
            image.send image_public_method, *args
          end
        end
      end
    end

    # Saves all images in the list to the output filename
    def save(output_filename)
      command_line = ""
      @images.each do |image|
        command_line << image.command_line
      end
      `convert #{command_line} "#{output_filename}"`
    end
    
    alias write save
    
    # Returns an array of images for the images stored
    def to_ary
      @images
    end
    
    alias to_a to_ary
    
    def <<(more_images)
      case more_images
        when QuickMagick::Image then @images << more_images
        # Another image list
        when QuickMagick::ImageList then self << more_images.to_a
        when Array then @images += more_images
        else raise QuickMagick::QuickMagickError, "Invalid argument type"
      end
      self
    end
  end

end