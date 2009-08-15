require 'test/unit'
require 'quick_magick'

$base_dir = File.dirname(File.expand_path(__FILE__))

class ImageTest < Test::Unit::TestCase
  
  def setup
    @logo_filename = File.join($base_dir, "imagemagick-logo.png")
    `convert magick:logo #{@logo_filename}`
    @small_logo_filename = File.join($base_dir, "logo-small.jpg")
    `convert magick:logo -resize 100x100! #{@small_logo_filename}`
  end
  
  def teardown
    File.delete(@logo_filename) if File.exists?(@logo_filename)
    File.delete(@small_logo_filename) if File.exists?(@small_logo_filename)
  end
  
  def test_open_existing_image
    i = QuickMagick::Image.read(@logo_filename)
    assert_equal 1, i.size
  end
  
  def test_create_from_blob
    blob = nil
    File.open(@logo_filename, "rb") do |f|
      blob = f.read
    end
    i = QuickMagick::Image.from_blob(blob)
    assert_equal 1, i.size
  end
  
  def test_image_info
    i = QuickMagick::Image.read(@logo_filename).first
    assert_equal 640, i.width
    assert_equal 480, i.height
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
    i = QuickMagick::Image.read(@logo_filename).first
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
    i = QuickMagick::Image.read(@logo_filename).first
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
    i = QuickMagick::Image.read(@logo_filename).first
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
    i = QuickMagick::Image.read(@logo_filename).first
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
  
  def test_line_and_circle
    i = QuickMagick::Image.solid(100, 100)
    i.draw_line(0,0,20,20)
    i.draw_circle(30,30,20,20)
    assert_equal %Q{ "(" -size "100x100" -draw " line 0,0 20,20  circle 30,30 20,20"  "xc:" ")" }, i.command_line
    out_filename = File.join($base_dir, "draw_test.gif")
    i.save out_filename
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_lines_with_colors
    i = QuickMagick::Image.solid(100, 100, :white)
    i.stroke = "red"
    i.draw_line(0,0,20,20)
    i.stroke = "blue"
    i.draw_circle(30,30,20,20)
    out_filename = File.join($base_dir, "draw_test.gif")
    i.save out_filename
  ensure
    # clean up
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_colors
    assert_equal "#00ff00ff", QuickMagick::rgb_color(0, 255, 0)
    assert_equal "#00007fff", QuickMagick::rgb_color(0, 0, 0.5)
    assert_equal "#3f0000ff", QuickMagick::rgb_color("25%" ,0 , 0)
    
    assert_equal "#ff00007f", QuickMagick::rgba_color(1.0, 0, 0, 0.5)

    assert_equal "#7f7f7f7f", QuickMagick::graya_color(0.5, 0.5)
    
    assert_equal "hsla(30,50%,50%,1)", QuickMagick::hsl_color(30, 127, 127)
    assert_equal "hsla(180,50%,50%,0.5)", QuickMagick::hsla_color(Math::PI, 0.5, "50%", 0.5)
  end
  
  def test_revert
    i = QuickMagick::Image.read(@logo_filename).first
    i.resize("300x300!")
    i.revert!
    out_filename = File.join($base_dir, "imagemagick-resized.png")
    File.delete out_filename if File.exists?(out_filename)
    i.save(out_filename)
    assert File.exists?(out_filename)
    i2 = QuickMagick::Image.read(out_filename).first
    assert_equal 640, i2.width
    assert_equal 480, i2.height
  end
end
