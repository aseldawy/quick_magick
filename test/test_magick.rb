require 'rubygems'
require 'mini_magick'
require 'quick_magick'
require 'RMagick'
require 'benchmark'
require 'ftools'
include Benchmark

$base_dir = File.dirname(File.expand_path(__FILE__))

# Generate a test file
in_file = File.join($base_dir, 'logo.png')
out_file = File.join($base_dir, 'testout.gif')

`convert magick:logo #{in_file}`

test_quick = lambda {
  image_filename = 
  20.times {
  	i = QuickMagick::Image.read(in_file).first
  	i.resize "100x100!"
  	i.save out_file
  }
}

test_mini = lambda {
  20.times {
  	i = MiniMagick::Image.from_file(in_file)
    i.combine_options do |c|
      c.resize "100x100!"
      c.format "gif"
    end
  	i.write out_file
  }
}

test_r = lambda {
  20.times {
  	i = Magick::Image.read(in_file).first
  	i = i.change_geometry!('100x100!') { |cols, rows, img|
  	  img.resize!(cols, rows)
  	}
  	i.write out_file
  }
}

puts "Test 1: resize a normal image"
bm(12) { |x|
	x.report("mini", &test_mini)
	x.report("quick", &test_quick)
	x.report("rmagick", &test_r)
}

File.delete(in_file) if File.exists?(in_file)
File.delete(out_file) if File.exists?(out_file)

##################################################

in_file = File.join($base_dir, '9.gif')
out_file = File.join($base_dir, 'testout.gif')

test_quick = lambda {
	i = QuickMagick::Image.read(in_file).first
	i.resize "8190x8190>"
	i.save out_file
}

test_mini = lambda {
	i = MiniMagick::Image.from_file(in_file)
  i.combine_options do |c|
    c.resize "8190x8190>"
    c.format "gif"
  end
	i.write out_file
}

test_r = lambda {
	i = Magick::Image.read(in_file).first
	i = i.change_geometry!('8190x8190>') { |cols, rows, img|
	  img.resize!(cols, rows)
	}
	i.write out_file
}

puts "Test 2: resize a large image"
bm(12) { |x|
	x.report("mini", &test_mini)
	x.report("quick", &test_quick)
  # Don't try RMagick! You'll regret that ... a lot :'(
#	x.report("rmagick", &test_r)
}

File.delete(out_file) if File.exists?(out_file)

##################################################

class String
  CHARS = ("a".."z").to_a + ("1".."9").to_a 
  def self.random(length)
    Array.new(length, '').collect{CHARS[rand(CHARS.size)]}.join
  end
end

def generate_captcha(length, width, height)
	captcha = []
	String.random(6).chars.each_with_index do |c, i|
	  letter = {}
	  letter[:char] = c
	  letter[:x] = width * i / length + (rand - 0.5) * width / length / 8
	  letter[:y] = height / 5 + (rand - 0.5) * height / 2
	  letter[:sx] = rand * 90 - 45
	  letter[:bx] = width * i / length + (rand - 0.5) * width / length / 2
	  letter[:by] = height / 2 + (rand - 0.5) * height
	  captcha << letter
	end
	captcha
end

out_file = File.join($base_dir, 'captcha.gif')

test_quick = lambda {
	i = QuickMagick::Image.solid(290, 70, :white)
	i.bordercolor = :black
	i.border = 5
	i.fill = :black
	i.stroke = :black
	i.strokewidth =  1
	i.pointsize = 40
	i.gravity = :northwest
	captcha = generate_captcha(6, 290, 70)
	captcha.each do |letter|
		i.draw_text letter[:x], letter[:y], letter[:char], :skewx=>letter[:sx]
	end
	i.save out_file
}

test_mini = lambda {
}

test_r = lambda {
	i = Magick::Image.new(290, 70)
	gc = Magick::Draw.new
	i.border! 5, 5, "black"
	gc.stroke "black"
	gc.stroke_width 1
	gc.pointsize 40
	gc.gravity = Magick::NorthWestGravity
	captcha = generate_captcha(6, 290, 70)
	captcha.each do |letter|
		gc.skewx letter[:sx]
		gc.text letter[:x], letter[:y], letter[:char]
	end
	gc.fill "none"
	gc.draw i
	i.write out_file
}

puts "Test 3: generate random captchas"
bm(12) { |x|
#	x.report("mini", &test_mini)
	x.report("quick", &test_quick)
	x.report("rmagick", &test_r)
}
# Cleanup temp files
File.delete(out_file) if File.exists?(out_file)
