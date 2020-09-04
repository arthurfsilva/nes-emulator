class PPU
  attr_accessor :name_table, :frame_completed, :nmi

  def initialize(bus)
    @bus = bus
    @cycle = 0
    @scanline = 0
    @cartridge = nil

    # Game Layout
    @name_table = []

    # Colors
    @palette = []
    
    # pattern_table memory (chr rom) sprites
    @pattern_table = Array.new(2) { Array.new(4096, 0)}

    @status = {
      unused: 5,
      sprite_overflow: 1,
      sprite_zero_hit: 1,
      vertical_blank: 1,
      reg: 0
    }

    @mask = {
      grayscale: 1,
      render_background_left: 1,
      render_sprites_left: 1,
      render_background: 1,
      render_sprites: 1,
      enhance_red: 1,
      enhance_green: 1,
      enhance_blue: 1,
      reg: 0
    }

    @control = {
      nametable_x: 1,
      nametable_y: 1,
      increment_mode: 1,
      pattern_table_sprite: 1,
      pattern_table_background: 1,
      sprite_size: 1,
      slave_mode: 1,
      enable_nmi: 1,
      reg: 0
    }

    @address_latch = 0
    @ppu_data_buffer = 0x00
    @ppu_address = 0x0000
    @frame_completed = false

    @nmi = false
  end

  def read(address)
    data = 0x00
    address &= 0x3FFF

    if @bus.cartridge.ppu_read(address, data)
    end

    case address
    when 0x0000 #Control

    when 0x0001 #Mask
      val = data & 3
    when 0x0002 #Status
      data = (@status[:reg] & 0xE0) | (@ppu_data_buffer & 0x1F)
      @status[:vertical_blank] = 0
      address_latch = 0
       
    when 0x0003 #OAM Address

    when 0x0004 #OAM Data

    when 0x0005 #Scroll

    when 0x0006 #PPU Address

    when 0x0007 #PPU Data
      data = @ppu_data_buffer 
      @ppu_data_buffer = ppu_read(ppu_address)

      if ppu_address > 0x3F00
        data = @ppu_data_buffer
      end

      @ppu_address += 1
    end

    data
  end

  def write(address, data)
    case address
    when 0x0000 #Control
      @control[:reg] = data
    when 0x0001 #Mask
      @mask[:reg] = data
    when 0x0002 #Status

    when 0x0003 #OAM Address

    when 0x0004 #OAM Data

    when 0x0005 #Scroll

    when 0x0006 #PPU Address
      if address_latch == 0
        @ppu_address = (@ppu_address & 0xFF00) | data
        @address_latch = 1
      else
        @ppu_address = (@ppu_address & 0x00FF) | data
        @address_latch = 0
      end
    when 0x0007 #PPU Data

    end
  end

  def ppu_read(addr, read_only = false)
    data = 0x00

    addr &= 0x3FFF

    if @cartridge.ppu_read(addr, data)

    elsif addr >= 0x0000 && addr <= 0x1FFF
      data = @pattern_table[(addr & 0x1000) >> 12][addr & 0x0FFF]
    elsif addr >= 0x2000 && addr <= 0x3EFF
      if @cartridge.mirror == 'vertical'
        if addr >= 0x0000 && addr <= 0x03FF
          data = @name_table[0][addr & 0x03FF]
        elsif addr >= 0x0400 && addr <= 0x07FF
          data = @name_table[1][addr & 0x03FF]
        elsif addr >= 0x0800 && addr <= 0x0BFF
          data = @name_table[0][0x03FF]
        elsif addr >= 0x0C00 && addr <= 0x0FFF
          data = @name_table[1][addr & 0x03FF]
        end
      elsif @cartridge.mirror = 'horizontal'
        if addr >= 0x0000 && addr <= 0x03FF
          data = @name_table[0][addr & 0x03FF]
        elsif addr >= 0x0400 && addr <= 0x07FF
          data = @name_table[0][addr & 0x03FF]
        elsif addr >= 0x0800 && addr <= 0x0BFF
          data = @name_table[1][addr & 0x03FF]
        elsif addr >= 0x0C00 && addr <= 0x0FFF
          data = @name_table[1][addr & 0x03FF]
        end
      end
    elsif addr >= 0x3F00 && addr <= 0x3FFF
      addr &= 0x001F

      #mirroring
      if addr == 0x0010
        addr = 0x0000
      end
      
      if addr == 0x0014
        addr = 0x0004
      end
      
      if addr == 0x0018
        addr = 0x0008
      end

      if addr == 0x001C
        addr = 0x000C
      end

      data = @palette[addr]
    end

    data
  end

  def ppu_write(addr, data)
    addr &= 0x3FFF
    
    if @cartridge.ppu_write(addr, data)

    elsif addr >= 0x0000 && addr <= 0x1FFF
      @pattern_table[(addr & 0x1000) >> 12][addr & 0x0FFF] = data
    elsif addr >= 0x2000 && addr <= 0x3EFF
      if @cartridge.mirror == 'vertical'
        if addr >= 0x0000 && addr <= 0x03FF
          @name_table[0][addr & 0x03FF] = data
        elsif addr >= 0x0400 && addr <= 0x07FF
          @name_table[1][addr & 0x03FF] = data
        elsif addr >= 0x0800 && addr <= 0x0BFF
          @name_table[0][addr & 0x03FF] = data
        elsif addr >= 0x0C00 && addr <= 0x0FFF
          @name_table[1][addr & 0x03FF] = data
        end
      elsif @cartridge.mirror = 'horizontal'
        if addr >= 0x0000 && addr <= 0x03FF
          @name_table[0][addr & 0x03FF] = data
        elsif addr >= 0x0400 && addr <= 0x07FF
          @name_table[0][addr & 0x03FF] = data
        elsif addr >= 0x0800 && addr <= 0x0BFF
          @name_table[1][addr & 0x03FF] = data
        elsif addr >= 0x0C00 && addr <= 0x0FFF
          @name_table[1][addr & 0x03FF] = data
        end
      end
    elsif addr >= 0x3F00 && addr <= 0x3FFF
      addr &= 0x001F

      #mirroring
      if addr == 0x0010
        addr = 0x0000
      end
      
      if addr == 0x0014
        addr = 0x0004
      end
      
      if addr == 0x0018
        addr = 0x0008
      end

      if addr == 0x001C
        addr = 0x000C
      end

      @palette[addr] = data
    end
  end

  def connect_cartridge(cartridge)
    @cartridge = cartridge
  end

  def clock
    if @scanline == -1 && @cycle == 1
      status[:vertical_blank] = 1
    end

    palette = 0x00
    pixel = 0x00

    if @scanline == 241 && @cycle == 1
      @status[:vertical_blank] = 1
      if @control[:enable_nmi]
        @nmi = true
      end
    end

  
    bg_next_tile_lsb = 0x00
    bg_next_tile_msb = 0x00    
    bit_mux = 0x00
    bg_shifter_pattern_table_lo = 0x00
    bg_shifter_pattern_table_hi = 0x00

		bg_shifter_pattern_table_lo = (bg_shifter_pattern_table_lo & 0xFF00) | bg_next_tile_lsb
		bg_shifter_pattern_table_hi = (bg_shifter_pattern_table_hi & 0xFF00) | bg_next_tile_msb

		bg_shifter_attrib_lo  = (bg_shifter_attrib_lo & 0xFF00) | ((bg_next_tile_lsb & 0b01) ? 0xFF : 0x00)
    bg_shifter_attrib_hi  = (bg_shifter_attrib_hi & 0xFF00) | ((bg_next_tile_msb & 0b10) ? 0xFF : 0x00)
    

    if @mask[:render_background]
      bit_mux = 0x8000 >> 1
      pixel0 = (bg_shifter_pattern_table_lo & bit_mux) > 0
      pixel1 = (bg_shifter_pattern_table_hi & bit_mux) > 0
      
      pixel = (pixel1 << 1) | pixel0

      bg_pal0 = (bg_shifter_attrib_lo & bit_mux) > 0
      uint8_t bg_pal1 = (bg_shifter_attrib_hi & bit_mux) > 0;
      bg_palette = (bg_pal1 << 1) | bg_pal0;
    end


    draw_pixel(@cycle - 1, @scanline, color_from_palette(palette, pixel))

    @cycle += 1

    if @cycle >= 341
      @cycle = 0
      @scanline += 1
      if @scanline >= 261
        @scanline -= 1
        @frame_completed = true
      end
    end
  end

  def pattern_table_table(i, palette)
    tile_x = 0
    tile_y = 0
    row = 0
    col = 0
    offset = 0

    while tile_y < 16
      while tile_x < 16
        offset = tile_y * 256 + tile_x * 16
        
        while row < 8
          tile_lsb = ppu_read(i * 0x1000 + offset + row + 0x0000)
          tile_msb = ppu_read(i * 0x1000 + offset + row + 0x0008)

          while col < 8
            pixel = (tile_lsb & 0x01) << 1 | (tile_msb & 0x01)

            tile_lsb >>= 1
            tile_msb >>= 1

            draw_pixel(tile_x * 8 + (7 - col), tile_y * 8 + row, color_from_palette(palette, pixel))

            col += 1
          end

          row += 1
        end

        tile_x += 1
      end
      tile_y += 1
    end
  end
 
  def color_from_palette(palette, pixel)
    ppu_read(0x3F00 + (palette << 2) + pixel)
  end

  def draw_pixel(x, y, color)
    s = Square.new(x: x, y: y, size: 1, color: color)
  end
end
