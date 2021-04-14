require 'rpi_gpio'
require 'spi'
require 'waveshare_epd/version'
require 'waveshare_epd/panels'

module EPD
  # Maps symbols to the relevant panel classes.
  PANEL_MODELS = {
    waveshare_2in7b_v2: EPD::Panels::Panel2in7B_V2,
    waveshare_7in5b_hd: EPD::Panels::Panel7in5B_HD
  }

  # Initializes a panel, and returns a Panel object.
  #
  # @param [Symbol] panel The model of panel used.
  # @param [Integer] cs The pin number for CS (chip select)
  # @param [Integer] rst The pin number for RST (reset)
  # @param [Integer] dc The pin number for DC (Data/Command)
  # @param [Integer] busy The pin nummber for BUSY (busy high)
  #
  # @return [EPD::Panel::Base] A panel based on the 
  #
  # @return [<type>] <description>
  #
  def self.start(panel, cs: 24, rst: 11, dc: 22, busy: 18)
      # Set up GPIO for non-SPI pins: CS (chip select), RST (reset), DC (data/command), BUSY

      RPi::GPIO.set_numbering :board

      RPi::GPIO.setup cs, as: :output
      RPi::GPIO.setup rst, as: :output
      RPi::GPIO.setup dc, as: :output
      RPi::GPIO.setup busy, as: :input
      
      spi = SPI.new(device: '/dev/spidev0.0')
      spi.speed = 2_000_000 # 2MHz

      yield PANEL_MODELS.fetch(panel).new(cs, rst, dc, busy, spi)

      RPi::GPIO.clean_up
  end
end