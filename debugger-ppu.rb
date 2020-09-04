# frozen_string_literal: true

require './lib/bus'
require 'ruby2d'
require 'pry'

nes = Bus.new
emulation_running = false
residual_time = 0.0

set title: 'NES EMULATOR', width: 800, height: 600

nes.insert_cartridge(ARGV[0])

set background: '#4d4d4d'

update do
  nes.clock()
end

show

