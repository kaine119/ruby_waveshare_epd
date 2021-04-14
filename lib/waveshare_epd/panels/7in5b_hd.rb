module EPD::Panels
  class Panel_7in5B_HD < PanelBase
    def power_on
      # hardware/software reset
      reset
      send_command(0x12) # Reset device parameters to default
      wait_for_panel

      # Driver output control
      send_command(0x01)
      send_data([0xaf, 0x02, 0x01]) # 0x2af gates, write backwards

      # Data entry mode
      send_command(0x11)
      send_data([0x01])

      # Data entry size (resolution of image)
      send_command(0x44) # x-res start/end (little-endian)
      send_data([0x00, 0x00, 0x6f, 0x03]) # start from 0x00, end at 0x36f (== 879)
      send_command(0x45)
      send_data([0xa7, 0x02, 0x00, 0x00]) # start from 0x2a7 (== 527), end at 0x00

      # Border waveform control? Let's try the default first
      send_command(0x3C)
      send_data([0xc0])

      # Use an appropriate LUT depending on the temperature.
      ## Select internal temp gauge
      send_command(0x18)
      send_data([0x80])

      ## Then tell the panel to choose the appropriate LUT based on the temperature?? idk
      send_command(0x22) # Set sequence to op b1
      send_data([0xb1])
      send_command(0x20) # Execute sequence
      wait_for_panel

      # Initialize RAM address
      send_command(0x4e)
      send_data([0x00, 0x00])
      send_command(0x4f)
      send_data([0xaf, 0x02])
    end

    def show_image_buffer(black_image, red_image)
      # Re-initialize the RAM address
      send_command(0x4e)
      send_data([0x00, 0x00])
      send_command(0x4f)
      send_data([0xaf, 0x02])

      # Send over the images
      send_command(0x24) # Write to BW RAM
      send_data(black_image)        
      send_command(0x26) # Write to RED RAM
      send_data(red_image)

      # Display the image
      send_command(0x22) # Load sequence C7 (display)
      send_data([0xc7])
      send_command(0x20) # Execute sequence
      sleep(0.2)
      wait_for_panel
    end

    def power_off
      send_command(0x10)
      send_data([0x01])
    end
  end
end