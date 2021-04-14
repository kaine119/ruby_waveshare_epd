require 'waveshare_epd'

image = Magick::Image.read('test.png').first.export_pixels_to_str

EPD.start(:waveshare_7in5b_hd) do |epd|
  epd.power_on
  epd.show_image(image)
  epd.power_off
end