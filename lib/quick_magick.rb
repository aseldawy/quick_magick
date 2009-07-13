# check that ImageMagick is installed
status = `identify --version`
raise QuickMagick::QuickMagickError "ImageMagick not installed" if status.empty?
require 'quick_magick/image'