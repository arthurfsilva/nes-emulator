# frozen_string_literal: true

require './lib/bus'
require 'ruby2d'
require 'pry'

nes = Bus.new
emulation_running = false
residual_time = 0.0

set title: 'NES EMULATOR', width: 1000, height: 800

obj = [ 0xA2, 0x0A, 0x8E, 0x00, 0x00, 0xA2, 0x03, 0x8E, 0x01, 0x00, 0xAC, 0x00, 0x00, 0xA9, 0x00, 0x18, 0x6D, 0x01, 0x00, 0x88, 0xD0, 0x0FA, 0x8D, 0x02, 0x00, 0xEA, 0xEA, 0xEA ]; #multiply

nes.insert_cartridge(ARGV[0])


set background: '#4d4d4d'

def draw_cpu(x, y, nes)
  Text.new(
    'STATUS: ',
    x: x, y: y,
    size: 13,
    color: 'white'
  )

  x += 50
  nes.cpu.flags.each do |flag|
    x += 15
    Text.new(
      flag[0],
      x: x, y: y,
      size: 13,
      color: nes.cpu.registers[:status] & nes.cpu.flags[flag[0]] != 0 ? 'green' : 'red'
    )
  end

  x = 600
  y = 20


  nes.cpu.registers.each do |register|
    Text.new(
      "#{register[0]}: $#{nes.cpu.registers[register[0]].to_s(16)}",
      x: x, y: y,
      size: 16,
      color: 'white'
    )
    y += 20
  end
end


def draw_code(nes)
  x = 600

  pc = nes.cpu.registers[:program_counter]

  current_opcode = nes.read(pc)


  opcode_name = 'NONE'

  if nes.cpu.lookup[current_opcode]

    if nes.cpu.lookup[current_opcode][:addr_mode].original_name == :IMM
      value = nes.read(pc + 1)
      addr = "{#{value}} {IMM}"
    end

    if nes.cpu.lookup[current_opcode][:addr_mode].original_name == :IMP
      addr = "{IMP}"
    end

    if nes.cpu.lookup[current_opcode][:addr_mode].original_name == :ABS
      pc += 1
      low = nes.read(pc, true)
      pc += 1
      high = nes.read(pc, true)

      addr = "{#{high.to_s(16)}#{low.to_s(16)}} {ABS}";
    end

    if nes.cpu.lookup[current_opcode][:addr_mode].original_name == :REL
      value = nes.read(pc + 1, true)
      addr = "#{value.to_s(16)} [ #{((pc + 2) + value).to_s(16)} ] {REL}";
    end

    opcode_name = nes.cpu.lookup[current_opcode][:name]
  end


  t = Text.new(
    "-> [ #{current_opcode.to_s(16).upcase} ] $#{current_opcode} -> #{opcode_name} #{addr}",
    x: x, y: 200,
    size: 20,
    color: 'white'
  )


end

def draw_ram(x, y, addr, rows, cols, nes)
  color = 'white'
  size = 11

  (0..rows).each do |row|
    offset = "$#{addr.to_s(16)}:"
    (0..cols).each do |col|
      if addr == nes.cpu.registers[:program_counter]
        offset += "  [#{nes.read(addr, true).to_s(16).upcase.rjust(2, '0')}] "
      else
        offset += "   #{nes.read(addr, true).to_s(16).upcase.rjust(2, '0')} "
      end
      addr += 1
    end

    mem = Text.new(
      offset,
      x: x, y: y,
      size: size,
      color: color
    )
    y += 15
  end
end

def draw_panels(nes, ram_scroll = 0xc000)
  clear


  #draw_ram(2, 2, 0x0000, 15, 15, nes)
  draw_ram(2, 2, ram_scroll, 45, 15, nes)
  draw_cpu(600, 2, nes)
  draw_code(nes)

  Text.new(
    "Space = Execute Instruction  F = Complete Frame   R = RESET    I = IRQ    N = NMI    G = Go to PC",
    x: 10, y: 760,
    size: 13,
    color: 'white'
  )
end

draw_panels(nes)


scroll = 0xc000
on :mouse_scroll do |event|
  if event.delta_y == 1
    scroll += 560
  else
    if scroll.positive?
      scroll -= 560
    end
  end
  draw_panels(nes, scroll)
end

on :key_down do |event|
  if event.key == 'space'

    loop do
      nes.clock()
    break if nes.cpu.complete() == false
    end

    loop do
      nes.cpu.clock()
    break if nes.cpu.complete() == true
    end

    draw_panels(nes)
  end

  if event.key == 'g'
    # todo
  end

  if event.key == 'f'

    loop do
      nes.clock()
    break if nes.ppu.frame_completed() == false
    end

    loop do
      nes.clock()
    break if nes.cpu.complete() == true
    end

    nes.ppu.frame_completed = false
  end

  if event.key == 'r'
    puts 'reset'
    nes.cpu.reset()
    draw_panels(nes)

  end

  if event.key == 'i'
    nes.cpu.irq()
    draw_panels(nes)

  end

  if event.key == 'n'
    nes.cpu.nmi()
    draw_panels(nes)

  end
end

show
