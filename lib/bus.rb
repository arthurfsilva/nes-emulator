require './lib/cpu'
require './lib/ppu'
require './lib/cartridge'

class Bus
  attr_accessor :memory, :system_clock, :cartridge, :cpu, :ppu, :cartridge

  def initialize
    @memory = []
    @cpu = CPU.new(self)
    @ppu = PPU.new(self)
    @cartridge = nil
    @controllers = nil
    @system_clock = 0
  end

  def read(address, read_only = false)
    if address >= 0x0000 && address <= 0x1FFF
      return memory[address]
    elsif address >= 0x2000 && address <= 0x3FFF
      return @ppu.read(address & 0x0007)
    end

    memory[address] || 0
  end

  def write(address, data)
    # if @cartridge.cpu_write(address, data)
    # end

    if address >= 0x0000 && address <= 0x1FFF
      memory[address & 0x07FF] = data
      return
    elsif address >= 0x2000 && address <= 0x3FFF
      @ppu.write(address & 0x0007, data)
      return
    end

    memory[address & 0x07FF] = data
  end

  def insert_cartridge(cartridge)
    @cartridge = Cartridge.new(cartridge)

    self.memory = @cartridge.rom

    high = read(0xFFFD)
    low = read(0xFFFC)

    @cpu.registers[:program_counter] = (high << 8) | low
    @ppu.connect_cartridge(@cartridge)
  end

  def reset
    @cpu.reset
    @system_clock = 0
  end

  def clock
    @ppu.clock

    if @system_clock % 3 == 0
      @cpu.clock
    end

    if @ppu.nmi
      ppu.nmi = false
      cpu.nmi();
    end
    
    @system_clock += 1
  end
end
