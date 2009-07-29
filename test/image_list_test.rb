require 'test/unit'
require 'quick_magick'
require 'ftools'

$base_dir = File.dirname(File.expand_path(__FILE__))

class ImageTest < Test::Unit::TestCase
  def test_open_file
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    i = QuickMagick::ImageList.new(image_filename)
    assert_equal 1, i.length
  end
  
  def test_save_multipage
    image_filename = File.join($base_dir, "imagemagick-logo.png")
    image_filename2 = File.join($base_dir, "logo-small.jpg")
    i = QuickMagick::ImageList.new(image_filename, image_filename2)
    assert_equal 2, i.length
    out_filename = File.join($base_dir, "out.tif")
    i.save out_filename
    
    i = QuickMagick::Image.read(out_filename)
    assert_equal 2, i.length
    assert_equal 100, i[1].width
  ensure
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_bulk_resize
    image_filename1 = File.join($base_dir, "imagemagick-logo.png")
    image_filename2 = File.join($base_dir, "logo-small.jpg")
    i = QuickMagick::ImageList.new(image_filename1, image_filename2)
    i.resize "50x50!"
    out_filename = File.join($base_dir, "out.tif")
    i.save out_filename
    
    i = QuickMagick::Image.read(out_filename)
    assert_equal 2, i.length
    assert_equal 50, i[0].width
    assert_equal 50, i[1].width
  ensure
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_append_image
    image_filename1 = File.join($base_dir, "imagemagick-logo.png")
    image_filename2 = File.join($base_dir, "logo-small.jpg")
    i = QuickMagick::ImageList.new
    i << QuickMagick::Image.read(image_filename1)
    i << QuickMagick::Image.read(image_filename2)
    i.resize "50x50!"
    out_filename = File.join($base_dir, "out.tif")
    i.save out_filename
    
    i = QuickMagick::Image.read(out_filename)
    assert_equal 2, i.length
    assert_equal 50, i[0].width
    assert_equal 50, i[1].width
  ensure
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_bulk_convert
    image_filename1 = File.join($base_dir, "imagemagick-logo.png")
    image_filename2 = File.join($base_dir, "logo-small.jpg")
    new_image_filename1 = File.join($base_dir, "temp1.png")
    new_image_filename2 = File.join($base_dir, "temp2.jpg")
    File.copy(image_filename1, new_image_filename1)
    File.copy(image_filename2, new_image_filename2)
    i = QuickMagick::ImageList.new(new_image_filename1, new_image_filename2)
    i.format = 'gif'
    i.save!
    
    out_filename1 = new_image_filename1.sub('.png', '.gif')
    out_filename2 = new_image_filename2.sub('.jpg', '.gif')
    assert File.exists?(out_filename1)
    assert File.exists?(out_filename2)
  ensure
    File.delete(new_image_filename1) if new_image_filename1 && File.exists?(new_image_filename1)
    File.delete(new_image_filename2) if new_image_filename2 && File.exists?(new_image_filename2)
    File.delete(out_filename1) if out_filename1 && File.exists?(out_filename1)
    File.delete(out_filename2) if out_filename2 && File.exists?(out_filename2)
  end
end