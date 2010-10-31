require 'test/unit'
require 'quick_magick'
require 'fileutils'

$base_dir = File.dirname(File.expand_path(__FILE__))

class ImageTest < Test::Unit::TestCase
  def setup
    @logo_filename = File.join($base_dir, "imagemagick-logo.png")
    `convert magick:logo "#{@logo_filename}"`
    @small_logo_filename = File.join($base_dir, "logo-small.jpg")
    `convert magick:logo -resize 100x100! "#{@small_logo_filename}"`
  end
  
  def teardown
    File.delete(@logo_filename) if File.exists?(@logo_filename)
    File.delete(@small_logo_filename) if File.exists?(@small_logo_filename)
  end

  def test_open_file
    i = QuickMagick::ImageList.new(@logo_filename)
    assert_equal 1, i.length
  end
  
  def test_save_multipage
    i = QuickMagick::ImageList.new(@logo_filename, @small_logo_filename)
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
    i = QuickMagick::ImageList.new(@logo_filename, @small_logo_filename)
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
    i = QuickMagick::ImageList.new
    i << QuickMagick::Image.read(@logo_filename)
    i << QuickMagick::Image.read(@small_logo_filename)
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
  
  def test_different_operators
    i = QuickMagick::ImageList.new
    i << QuickMagick::Image.read(@logo_filename)
    i << QuickMagick::Image.read(@small_logo_filename)
    i[0].resize "50x50!"
    i[1].resize "75x75!"
    out_filename = File.join($base_dir, "out.tif")
    i.save out_filename
    
    i = QuickMagick::Image.read(out_filename)
    assert_equal 2, i.length
    assert_equal 50, i[0].width
    assert_equal 75, i[1].width
  ensure
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_resize_one_image_in_a_list
    i = QuickMagick::ImageList.new
    i << QuickMagick::Image.read(@logo_filename)
    i << QuickMagick::Image.read(@small_logo_filename)
    i[0].resize "50x50!"
    out_filename = File.join($base_dir, "out.tif")
    i.save out_filename
    
    i = QuickMagick::Image.read(out_filename)
    assert_equal 2, i.length
    assert_equal 50, i[0].width
    assert_equal 100, i[1].width
  ensure
    File.delete(out_filename) if out_filename && File.exists?(out_filename)
  end
  
  def test_bulk_convert
    i = QuickMagick::ImageList.new(@logo_filename, @small_logo_filename)
    i.format = 'gif'
    i.save!
    
    out_filename1 = @logo_filename.sub('.png', '.gif')
    out_filename2 = @small_logo_filename.sub('.jpg', '.gif')
    assert File.exists?(out_filename1)
    assert File.exists?(out_filename2)
  ensure
    File.delete(out_filename1) if out_filename1 && File.exists?(out_filename1)
    File.delete(out_filename2) if out_filename2 && File.exists?(out_filename2)
  end
end