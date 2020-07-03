class PPU
  attr_accessor :table_name, :frame_completed

  def initialize(bus)
    @cycle = 0
    @scanline = 0
    @bus = bus
    @table_name = []
    @palette = []
    @pattern = []
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

    when 0x0003 #OAM Address

    when 0x0004 #OAM Data

    when 0x0005 #Scroll

    when 0x0006 #PPU Address

    when 0x0007 #PPU Data

    end

    return data
  end

  def write(address, data)
    case address
    when 0x0000 #Control

    when 0x0001 #Mask

    when 0x0002 #Status

    when 0x0003 #OAM Address

    when 0x0004 #OAM Data

    when 0x0005 #Scroll

    when 0x0006 #PPU Address

    when 0x0007 #PPU Data

    end
  end

  def ppu_read(addr, read_only = false)
    data = 0x00

    addr &= 0x3FFF

    if @cartridge.ppu_read(addr, data)
    end

    data
  end

  def ppu_write(addr)
    data = 0x00
    addr &= 0x3FFF

    if @cartridge.ppu_write(addr)
    end
  end

  def connect_cartridge(cartridge)
    @cartridge = cartridge
  end

  def clock
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
end
