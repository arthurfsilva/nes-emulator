class Cartridge
  attr_accessor :rom, :vram, :prg_memory, :chr_memory, :mapper, :prg_banks, :mirror

  def initialize(filename)
    header = {
      name: nil,
      program_rom_chunks: nil,
      character_rom_chunks: nil,
      mapper1: 0,
      mapper2: 0,
      prg_ram_size: nil,
      tv_system1: nil,
      tv_system2: nil,
      unused: nil
    }

    @rom = []
    @vram = []

    rom = File.open(filename, 'rb').readlines
    header_rom = rom[0]

    unless header_rom[0] == 'N' && header_rom[1] == 'E' && header_rom[2] == 'S' && header_rom[3] == "\x1A"
      raise 'Invalid nes rom'
    end

    rom_result = []
    i = 0

    rom.each do |line|
      line.each_byte do |char|
        rom_result[i] = char
        i += 1
      end
    end

    @prg_banks = rom_result[4].to_i
    @chr_banks = rom_result[5].to_i
    @mapper = (((rom_result[6].to_i & 0xF0) >> 4) | rom_result[7].to_i & 0xF0)
    is_horizontal_mirror = !(rom_result[6].to_i & 0x01)

    if is_horizontal_mirror
      @mirror = 'horizontal'
    else
      @mirror = 'vertical'
    end

    display_cartridge_info(filename, @prg_banks,  @chr_banks,  @mapper)

   if @mapper != 0
    raise 'This rom is not compatible please try another one!'
   end

    index = 0x0000

    while index <= 0xFFFF
      @rom[index] = 0x00
      index += 1
    end

    nOffset = 0x8000
    obj = rom_result[16..0x400f]

    obj.each do |o|
      @rom[nOffset] = o
      nOffset += 1
    end

    if @prg_banks == 1
      nOffset = 0xC000
      obj = rom_result[16..@prg_banks*0x400f]

      obj.each do |o|
        @rom[nOffset] = o
        nOffset += 1
      end
    end

    aa = 16 + 0x400f*@prg_banks

    @vram = rom_result[aa..aa + 0x2000*@chr_banks]
  end

  def cpu_read(address)
    mapped_address = 0x00

    if address > 0x8000 && address <= 0xFFFF
      @mapped_address = address & (@program_rom_banks > 1 ? 0x7FFF : 0x3FFF)

      @data = @prg_memory[mapped_address]

      return true

    end
  end

  def cpu_write(address, mapped_address)
    mapped_address = 0x00

    if address > 0x8000 && address <= 0xFFFF
      @data = @prg_memory[mapped_address]

      return true
    end
  end

  def ppu_read(address, mapped_address)
    mapped_address = 0x00

    if address > 0x8000 && address <= 0x1FFF
      @data = @chr_memory[mapped_address]

      return true
    end
  end

  def ppu_write(address, data)
    mapped_address = 0x00
    if address >= 0x8000 && address <= 0xFFFF
      mapped_address = address & (@prg_banks > 1 ? 0x7FFF : 0x3FFF);

      @chr_memory[mapped_address] = data

      return true
    end

    false
  end

  def display_cartridge_info(filename, prg_chunks, chr_chunks, mapper)
    puts "#{filename}"
    puts "Program ROM pages: \e[35m#{prg_chunks}\e[0m"
    puts "Character ROM pages: \e[35m#{chr_chunks}\e[0m"
    puts "Mapper: \e[35m#{mapper}\e[0m"
    puts "==============================================="
  end
end
