require 'rpi_gpio'

module EPD::Panels
  class Base
    # Creates a Panel object. Use EPD.start for the panel instead.
    # 
    # To implement a new display, inherit this class and override power_on, show_image and power_off
    #   with the appropriate SPI calls, using reset send_command, send_data and wait_for_panel.
    #   Also define WIDTH and HEIGHT.
    #
    # @param [FixNum] cs The CS pin number
    # @param [FixNum] rst the RST pin number
    # @param [FixNumb] dc The DC pin number
    # @param [FixNum] busy The BUSY pin number
    # @param [SPI] spi The SPI object to be used for the current instance.
    def initialize(cs, rst, dc, busy, spi)
      @cs = cs # active low
      @rst = rst # active low
      @dc = dc # 0 for command, 1 for data
      @busy = busy # active high; a high signal indicates the panel is busy
      @spi = spi
    end

    # Power on the display.
    # @raise [NotImplementedError] if this method is called; implement logic per panel!
    def power_on
      raise NotImplementedError
    end

    # Show an image on the display. The image must be black-and-white (-and-red, for supported displays),
    # and must be passed in as a byte array.
    # @param [String] buffer The image as a series of pixel bytes (e.g. [65535, 65535, 65535, 0, 0, 0] for 1 white pixel next to 1 black pixel.
    def show_image(buffer)
      # We need to squish 8 pixels (3 bytes each) into 2 images of 1 byte.
      # (i.e. a black-and-white image of 8 pixels needs to turn from 
      # [[0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00], [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00], [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00], [0xFF, 0xFF, 0xFF], [0x00, 0x00, 0x00]]
      # to 0b10101010 (one bit per pixel, instead of 3 bytes). 
      # Red pixels will be saved off as a separate image.
      black_image, red_image = [], []
      buffer.each_byte.each_slice(3).each_slice(8) do |chunk|
        black_image_chunk = 0
        red_image_chunk = 0
        # for each chunk of 8 pixels, construct a 8-bit number from each of the pixels.
        chunk.each_with_index do |pixel, i|
          # Write from left to right.
          index_to_write = 7 - i
          # if the pixel is white, write a 1 on both the red and black image chunk
          if pixel.all?(0xff)
            black_image_chunk |= 1 << index_to_write
            red_image_chunk |= 1 << index_to_write
          # if the pixel is black, write a 0 on the black image, and a 1 on the red image
          elsif pixel.all?(0x00)
            black_image_chunk |= 0 << index_to_write
            red_image_chunk |= 1 << index_to_write
          # any other color will be interpreted as red; write a 1 on the black image and a 0 on the red image
          else
            black_image_chunk |= 1 << index_to_write
            red_image_chunk |= 0 << index_to_write
          end
        end
      end
      show_image_buffer(black_image, red_image)
    end

    # Transfer and display a converted image buffer on the display.
    # @param [Array<FixedNum>] black_buffer The single-bit buffer for the black image.
    # @param [Array<FixedNum>] red_buffer The single-bit buffer for the red image.
    # @raise [NotImplementedError] if this method is called; implement logic per panel!
    def show_image_buffer(black_buffer, red_buffer)
      raise NotImplementedError
    end

    # Power off the display.
    # @raise [NotImplementedError] if this method is called; implement logic per panel!
    def power_off
      raise NotImplementedError
    end

    # Send a command down the SPI line.
    # @param [FixNum] command The hex command to send down the line.
    def send_command(command)
      # Enable the chip, set the DC line to COMMAND
      RPi::GPIO.set_low @cs
      RPi::GPIO.set_low @dc
      # Now send the command over the SPI line
      @spi.xfer(txdata: [command])
      # We're done, turn off CS
      RPi::GPIO.set_high @cs
    end

    # Send some data down the SPI line.
    # @param [Array<FixNum>] data The data to send down the line.
    def send_data(data)
      # Enable the chip, set the DC line to DATA
      RPi::GPIO.set_low @cs
      RPi::GPIO.set_high @dc
      # Now send the command over the SPI line
      @spi.xfer(txdata: data)
      # We're done, turn off CS
      RPi::GPIO.set_high @cs
    end

    # Wait for the Panel to turn off the BUSY flag.
    def wait_for_panel
      puts "Waiting for panel..."
      RPi::GPIO.wait_for_edge(@busy, :falling)
      puts "Panel is done!"
    end

    # Hardware-reset the panel by sending a pulse down the RST pin.
    def reset
      # Leave the RST pin high for a bit, then pulse the RST pin low for 4ms.
      RPi::GPIO.set_high @rst
      sleep 0.200
      RPi::GPIO.set_low @rst # resets the panel.
      sleep 0.004
      RPi::GPIO.set_high @rst
    end
  end
end
