require 'test/unit'
require 'quick_magick'

$base_dir = File.dirname(File.expand_path(__FILE__))

class ImageTest < Test::Unit::TestCase
  def test_open_existing_image
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename)
    assert_equal 1, i.size
  end
  
  def test_create_from_blob
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    blob = nil
    File.open(image_filename, "rb") do |f|
      blob = f.read
    end
    i = QuickMagick::Image.from_blob(blob)
    assert_equal 1, i.size
  end
  
  def test_image_info
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename).first
    assert_equal 464, i.width
    assert_equal 479, i.height
  end
  
  def test_open_non_existing_file
    image_filename = File.join($base_dir, "space.png")
    assert_raises QuickMagick::QuickMagickError do
      i = QuickMagick::Image.read(image_filename)
    end
  end
  
  def test_open_bad_file
    image_filename = File.join($base_dir, "badfile.xxx")
    assert_raises QuickMagick::QuickMagickError do
      i = QuickMagick::Image.read(image_filename)
    end
  end
  
  def test_open_mulitpage_file
    image_filename = File.join($base_dir, "multipage.tif")
    i = QuickMagick::Image.read(image_filename)
    assert_equal 2, i.size
    assert_equal 100, i[0].width
    assert_equal 464, i[1].width
  end

  def test_resize_image
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename).first
    i.resize("300x300!")
    out_filename = File.join($base_dir, "imagemagick-resized.png")
    File.delete out_filename if File.exists?(out_filename)
    i.save(out_filename)
    assert File.exists?(out_filename)
    i2 = QuickMagick::Image.read(out_filename).first
    assert_equal 300, i2.width
    assert_equal 300, i2.height
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_crop_image
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename).first
    i.crop("300x200+0+0")
    out_filename = File.join($base_dir, "imagemagick-cropped.png")
    File.delete out_filename if File.exists?(out_filename)
    i.save(out_filename)
    assert File.exists?(out_filename)
    i2 = QuickMagick::Image.read(out_filename).first
    assert_equal 300, i2.width
    assert_equal 200, i2.height
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_resize_with_geometry_options
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename).first
    i.resize(300, 300, nil, nil, QuickMagick::AspectGeometry)
    out_filename = File.join($base_dir, "imagemagick-resized.png")
    File.delete out_filename if File.exists?(out_filename)
    i.save(out_filename)
    assert File.exists?(out_filename)
    i2 = QuickMagick::Image.read(out_filename).first
    assert_equal 300, i2.width
    assert_equal 300, i2.height
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_resize_with_append_to_operators
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::Image.read(image_filename).first
    i.append_to_operators 'resize', '300x300!'
    out_filename = File.join($base_dir, "imagemagick-resized.png")
    File.delete out_filename if File.exists?(out_filename)
    i.save(out_filename)
    assert File.exists?(out_filename)
    i2 = QuickMagick::Image.read(out_filename).first
    assert_equal 300, i2.width
    assert_equal 300, i2.height
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_create_solid_image
    i = QuickMagick::Image.solid(100, 100, :white)
    assert_equal 100, i.width
  end
  
  def test_create_gradient_image
    i = QuickMagick::Image.gradient(100, 100, QuickMagick::RadialGradient, :yellow, :blue)
    assert_equal 100, i.width
  end
  
  def test_line_primitive
    i = QuickMagick::Image.solid(100, 100, :white)
    i.draw_line(0, 0, 50, 50)
    out_filename = File.join($base_dir, "line_test.gif")
    i.save out_filename
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_text_primitive
    i = QuickMagick::Image.solid(100, 100, :white)
    i.draw_text(0, 50, "Ahmed Eldawy")
    out_filename = File.join($base_dir, "text_test.gif")
    i.save out_filename
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
end