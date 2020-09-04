class CPU
  attr_accessor :registers, :flags, :opcode, :lookup, :addr_abs

  def initialize(bus)
    @bus = bus

    @flags = {
      C: (1 << 0), # 1 - Carry Bit
      Z: (1 << 1), # 2 - Zero
      I: (1 << 2), # 4 - Disable Interrupts
      D: (1 << 3), # 8 - Decimal Mode
      B: (1 << 4), # 16 - Break
      U: (1 << 5), # 32 - Unused
      V: (1 << 6), # 64 - Overflow
      N: (1 << 7)  # 128 - Negative
    }

    @registers = {
      a: 0x00,
      x: 0x00,
      y: 0x00,
      stack_pointer: 0xFD,
      program_counter: 0x0000,
      status: 0x00
    }

    @fetched = 0x00

    # Depending address mode read data from different locations
    # in memory
    @addr_abs = 0x0000

    @addr_rel = 0x00
    @opcode = 0x00
    @cycles = 0

    @lookup = [
      { name: "BRK", operate: self.method(:BRK), addr_mode: self.method(:IMM), cycles: 7 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "ASL", operate: self.method(:ASL), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "PHP", operate: self.method(:PHP), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "ASL", operate: self.method(:ASL), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "ASL", operate: self.method(:ABS), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BPL", operate: self.method(:BPL), addr_mode: self.method(:REL), cycles: 2 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "ASL", operate: self.method(:ASL), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "CLC", operate: self.method(:CLC), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ORA", operate: self.method(:ORA), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "ASL", operate: self.method(:ASL), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "JSR", operate: self.method(:JSR), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "BIT", operate: self.method(:BIT), addr_mode: self.method(:ZP0), cycles: 3},
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "ROL", operate: self.method(:ROL), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "PLP", operate: self.method(:PLP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "ROL", operate: self.method(:ROL), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "BIT", operate: self.method(:BIT), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "ROL", operate: self.method(:ROL), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BMI", operate: self.method(:BMI), addr_mode: self.method(:REL), cycles: 2 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "ROL", operate: self.method(:ROL), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "SEC", operate: self.method(:SEC), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "AND", operate: self.method(:AND), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "ROL", operate: self.method(:ROL), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "RTI", operate: self.method(:RTI), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "LSR", operate: self.method(:LSR), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "PHA", operate: self.method(:PHA), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "LSR", operate: self.method(:LSR), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "JMP", operate: self.method(:JMP), addr_mode: self.method(:ABS), cycles: 3 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "LSR", operate: self.method(:LSR), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BVC", operate: self.method(:BVC), addr_mode: self.method(:REL), cycles: 2 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "LSR", operate: self.method(:LSR), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "CLI", operate: self.method(:CLI), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "EOR", operate: self.method(:EOR), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "LSR", operate: self.method(:LSR), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "RTS", operate: self.method(:RTS), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "ROR", operate: self.method(:ROR), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "PLA", operate: self.method(:PLA), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "ROR", operate: self.method(:ROR), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "JMP", operate: self.method(:JMP), addr_mode: self.method(:IND), cycles: 5 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "ROR", operate: self.method(:ROR), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BVS", operate: self.method(:BVS), addr_mode: self.method(:REL), cycles: 2 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "ROR", operate: self.method(:ROR), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "SEI", operate: self.method(:SEI), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "ADC", operate: self.method(:ADC), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "ROR", operate: self.method(:ROR), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "STY", operate: self.method(:STY), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "STX", operate: self.method(:STX), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "DEY", operate: self.method(:DEY), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "TXA", operate: self.method(:TXA), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "STY", operate: self.method(:STY), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "STX", operate: self.method(:STX), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "BCC", operate: self.method(:BCC), addr_mode: self.method(:REL), cycles: 2 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:IZY), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "STY", operate: self.method(:STY), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "STX", operate: self.method(:STX), addr_mode: self.method(:ZPY), cycles: 4 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "TYA", operate: self.method(:TYA), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:ABY), cycles: 5 },
      { name: "TXS", operate: self.method(:TXS), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "STA", operate: self.method(:STA), addr_mode: self.method(:ABX), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "LDY", operate: self.method(:LDY), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "LDX", operate: self.method(:LDX), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "LDY", operate: self.method(:LDY), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "LDX", operate: self.method(:LDX), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 3 },
      { name: "TAY", operate: self.method(:TAY), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "TAX", operate: self.method(:TAX), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "LDY", operate: self.method(:LDY), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "LDX", operate: self.method(:LDX), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "BCS", operate: self.method(:BCS), addr_mode: self.method(:REL), cycles: 2 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "LDY", operate: self.method(:LDY), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "LDX", operate: self.method(:LDX), addr_mode: self.method(:ZPY), cycles: 4 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "CLV", operate: self.method(:CLV), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "TSX", operate: self.method(:TSX), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "LDY", operate: self.method(:LDY), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "LDA", operate: self.method(:LDA), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "LDX", operate: self.method(:LDX), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "CPY", operate: self.method(:CPY), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "CPY", operate: self.method(:CPY), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "DEC", operate: self.method(:DEC), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "INY", operate: self.method(:INY), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "DEX", operate: self.method(:DEX), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "CPY", operate: self.method(:CPY), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "DEC", operate: self.method(:DEC), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BNE", operate: self.method(:BNE), addr_mode: self.method(:REL), cycles: 2 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "DEC", operate: self.method(:DEC), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "CLD", operate: self.method(:CLD), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "NOP", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "CMP", operate: self.method(:CMP), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "DEC", operate: self.method(:DEC), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "CPX", operate: self.method(:CPX), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:IZX), cycles: 6 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "CPX", operate: self.method(:CPX), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:ZP0), cycles: 3 },
      { name: "INC", operate: self.method(:INC), addr_mode: self.method(:ZP0), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 5 },
      { name: "INX", operate: self.method(:INX), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:IMM), cycles: 2 },
      { name: "NOP", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:SBC), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "CPX", operate: self.method(:CPX), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:ABS), cycles: 4 },
      { name: "INC", operate: self.method(:INC), addr_mode: self.method(:ABS), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "BEQ", operate: self.method(:BEQ), addr_mode: self.method(:REL), cycles: 2 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:IZY), cycles: 5 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 8 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:ZPX), cycles: 4 },
      { name: "INC", operate: self.method(:INC), addr_mode: self.method(:ZPX), cycles: 6 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 6 },
      { name: "SED", operate: self.method(:SED), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:ABY), cycles: 4 },
      { name: "NOP", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 2 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7 },
      { name: "???", operate: self.method(:NOP), addr_mode: self.method(:IMP), cycles: 4 },
      { name: "SBC", operate: self.method(:SBC), addr_mode: self.method(:ABX), cycles: 4 },
      { name: "INC", operate: self.method(:INC), addr_mode: self.method(:ABX), cycles: 7 },
      { name: "???", operate: self.method(:INVALID), addr_mode: self.method(:IMP), cycles: 7}
    ];
  end

  # Address Modes
  def IMP
    @fetched = @registers[:a]

    0
  end

  def IMM
    @addr_abs = @registers[:program_counter]

    @registers[:program_counter] += 1

    0
  end

  def ZP0
    @addr_abs = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1
    @addr_abs &= 0x00FF

    0
  end

  def ZPX
    @addr_abs = @bus.read(@registers[:program_counter] + @registers[:x])
    @registers[:program_counter] += 1
    @addr_abs &= 0x00FF

    0
  end

  def ZPY
    @addr_abs = @bus.read(@registers[:program_counter] + @registers[:y])
    @registers[:program_counter] += 1
    @addr_abs &= 0x00FF

    0
  end

  def REL()
    @addr_rel = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    # if (@addr_rel & 0x80) != 0
    #   @addr_rel |= 0xFF00
    # end

    0
  end

  def ABS
    low = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    high = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    @addr_abs = (high << 8) | low

    0
  end

  def ABX
    low = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    high = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    @addr_abs = (high << 8) | low
    @addr_abs += @registers[:x]

    if (@addr_abs & 0xFF00) != (high << 8)
      return 1
    else
      return 0
    end
  end

  def ABY
    low = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1
    high = @bus.read(@registers[:program_counter])

    @registers[:program_counter] += 1

    @addr_abs = (high << 8) | low
    @addr_abs += @registers[:y]

    if (@addr_abs & 0xFF00) != (high << 8)
      return 1
    else
      return 0
    end
  end

  def IND
    pointer_low = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    pointer_high = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    pointer = (pointer_high << 8) | pointer_low
    if (pointer_low == 0x00FF)
      @addr_abs = (@bus.read(pointer + 0x00FF) << 8) | @bus.read(pointer + 0)
    else
      @addr_abs = (@bus.read(pointer + 1) << 8) | @bus.read(pointer + 0)
    end

    0
  end

  def IZX
    t = @bus.read(@registers[:program_counter])
    x = @registers[:x]

    @registers[:program_counter] += 1

    low = @bus.read((t + x) & 0x00FF)
    high = @bus.read((t + x + 1) & 0x00FF)

    @addr_abs = (high << 8) | low

    0
  end

  def IZY
    t = @bus.read(@registers[:program_counter])
    @registers[:program_counter] += 1

    low = @bus.read(t & 0x00FF)
    high = @bus.read((t + 1) & 0x00FF)

    @addr_abs = (high << 8) | low

    @addr_abs += @registers[:y]

    if ((@addr_abs & 0xFF00) != (high << 8))
      return 1
    end

    0
  end
  # END ADDRESS MODES


  # ---- OPCODES ----
  def ADC()
    fetch()
    temp = @registers[:a] + @fetched + get_status(:C)
    set_status(:C, temp > 255)
    set_status(:Z, (temp & 0x00FF) == 0)
    set_status(:N, temp & 0x80)
    set_status(:V, (~(@registers[:a] ^ @fetched)) & (@registers[:a] ^ temp) & 0x0080)

    @registers[:a] = temp & 0x00FF

    1
  end

  def SBC()
    fetch()
    value = @fetched ^ 0x00FF
    temp = @registers[:a] + value + get_status(:C)
    set_status(:C, temp & 0x00FF)
    set_status(:Z, (temp & 0x00FF) == 0)
    set_status(:N, temp & 0x80)
    set_status(:V, (temp ^ @registers[:a]) & (temp ^ value) & 0x0080)

    @registers[:a] = temp & 0x00FF

  end

  def AND()
    fetch();
    @registers[:a] = @registers[:a] & @fetched
    set_status(:Z, @registers[:a] == 0x00)
    set_status(:N, @registers[:a] & 0x80)

    1
  end

  def ASL()
    fetch()

    temp = @fetched << 1

    set_status(:Z, (temp & 0x00FF) == 0x00)
    set_status(:N, temp & 0x80)
    set_status(:C, (temp & 0xFF00) > 0)

    if @lookup[@opcode][:addr_mode].equal? self.IMP
      @registers[:a] = temp & 0x00FF
    else
      @bus.write(@addr_abs, temp & 0x00FF)
    end

    0
  end

  def BCC()
    if (get_status(:C) == 0)
      @cycles += 1
      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end

  def BCS()
    if (get_status(:C) == 1)
      @cycles += 1
      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end
    
  def BEQ()
    if (get_status(:Z) == 1)
      @cycles += 1
      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end

  def BIT()
    fetch()
    temp = @registers[:a] & @fetched
    set_status(:Z, (temp & 0x00FF) == 0)
    set_status(:N, @fetched & (1 << 7))
    set_status(:V, @fetched & (1 << 6))

    0
  end

  def BMI()
    if (get_status(:N) == 1)
      @cycles += 1
      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end

  def BNE()
    if (get_status(:Z) == 0)
      @cycles += 1

      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs #0x8010
    end

    0
  end

  def BPL()
    if (get_status(:N) == 0)
      @cycles += 1

      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end

  def BRK()
    @registers[:program_counter] += 1
    set_status(:I, 1)

    @bus.write(0x0100 + @registers[:stack_pointer], (@registers[:program_counter] & 0xFF00) >> 8)
    @registers[:stack_pointer] -= 1


    @registers[:program_counter] += 1
    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:program_counter] & 0xFF)
    @registers[:stack_pointer] -= 1

    set_status(:B, 1)
    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:status])
    @registers[:stack_pointer] -= 1

    set_status(:B, 0)

    @registers[:program_counter] = (@bus.read(0xFFFF) << 8) | @bus.read(0xFFFE)

    0
  end


  def BVC()
    if get_status(:V) == 0
      @addr_abs = @registers[:program_counter] + @addr_rel

      if ((@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00))
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs #0x8010
    end

    0
  end

  def BVS()
    if get_status(:V) != 0
      @cycles +=1

      @addr_abs = @registers[:program_counter] + @addr_rel

      if (@addr_abs & 0xFF00) != (@registers[:program_counter] & 0xFF00)
        @cycles += 1
      end

      @registers[:program_counter] = @addr_abs
    end

    0
  end

  def CLC()
    set_status(:C, false)

    0
  end

  def CLD()
    set_status(:D, false)

    0
  end

  def CLI()
    set_status(:I, false)

    0
  end

  def CLV()
    set_status(:V, false)

    0
  end

  def CMP()
    fetch

    temp = @registers[:a] - @fetched

    set_status(:Z, temp == 0x00)
    set_status(:N, temp & 0x80)

    0
  end

  def CPX()
    fetch

    temp = @registers[:x] - @fetched

    set_status(:Z, temp == 0x00)
    set_status(:N, temp & 0x80)

    0
  end

  def CPY()
    fetch

    temp = @registers[:y] - @fetched

    set_status(:Z, temp == 0x00)
    set_status(:N, temp & 0x80)

    0
  end

  def DEC()
    fetch
    temp = @fetched - 1

    @bus.write(@addr_abs, temp & 0x00FF)

    set_status(:N, temp & 0x80)
    set_status(:Z, (temp & 0x00FF) == 0x0000)

    0
  end

  def DEX()
    @registers[:x] -= 1

    set_status(:N, @registers[:x] & 0x80)
    set_status(:Z, @registers[:y] == 0x00)

    0
  end

  def DEY()
    @registers[:y] -= 1

    set_status(:Z, @registers[:y] == 0X00)
    set_status(:N, @registers[:y] & 0x80)

    0
  end

  def EOR()
    fetch

    temp = @registers[:a] ^ @fetched

    set_status(:Z, temp == 0x00)
    set_status(:N, temp & 0x80)

    0
  end

  def INC()
    fetch

    temp = @fetched + 1

    @bus.write(@addr_abs, temp & 0x00FF) # & 0x00FF evita valores maior que 255 caso for maior seta para 0

    set_status(:Z, (temp & 0x00FF) == 0x00)
    set_status(:N, temp & 0x80)


    0
  end

  def INX()
    @registers[:x] += 1

    set_status(:Z, (@registers[:x] & 0x00FF) == 0x00)
    set_status(:N, @registers[:x] & 0x80)

    0
  end

  def INY()
    @registers[:y] += 1

    set_status(:Z, (@registers[:x] & 0x00FF) == 0x00)
    set_status(:N, @registers[:x] & 0x80)

    0
  end

  def JMP()
    @registers[:program_counter] = @addr_abs

    0
  end

  def JSR()
    @registers[:program_counter] -= 1

    @bus.write(0x0100 + @registers[:stack_pointer], (@registers[:program_counter] >> 8) & 0x00FF)
    @registers[:stack_pointer] -= 1

    @bus.write(0x0100 + @registers[:stack_pointer], (@registers[:program_counter] & 0x00FF))
    @registers[:stack_pointer] -= 1

    @registers[:program_counter] = @addr_abs

    0
  end


  def LDA()
    fetch
	  @registers[:a] = @fetched

    set_status(:Z, @registers[:a] == 0x00)
    set_status(:N, @registers[:a] & 0x80)

    1
  end

  def LDX()
    fetch

    @registers[:x] = @fetched

    set_status(:Z, @registers[:x] == 0x00)
    set_status(:N, @registers[:x] & 0x80)

    1
  end

  def LDY()
    fetch

    @registers[:y] = @fetched

    set_status(:Z, @registers[:y] == 0x00)
    set_status(:N, @registers[:y] & 0x80)

    0
  end

  def LSR()
    fetch

    set_status(:C, @fetched & 0x0001)
    temp = @fetched >> 1

    set_status(:Z, (temp & 0x00FF) == 0x0000)
    set_status(:N, temp & 0x80)

    if @lookup[@opcode][:addr_abs].equal? self.IMP
      @registers[:a] = temp & 0x00FF
    else
      @bus.write(@addr_abs, temp & 0x00FF)
    end

    0
  end

  def NOP()
    case @opcode
      when 0x1C
      when 0x3C
      when 0x5C
      when 0x7C
      when 0xDC
      when 0xFC
        return 1
    end

    0
  end

  def ORA()
    fetch

    temp = @registers[:a] | @fetched

    @registers[:a] = temp

    set_status(:Z, (temp & 0x00FF) == 0x00)
    set_status(:N, temp & 0x80)

    0
  end

  def PHA()
    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:a])
    @registers[:stack_pointer]--
    0
  end

  def PHP()
    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:status] | get_status(:B) | get_status(:U))
    set_status(:B, 0)
    set_status(:U, 0)

    @registers[:stack_pointer] -= 1

    0
  end

  def PLA()
    @registers[:stack_pointer]++
    @registers[:a] = @bus.read(0x0100 + @registers[:stack_pointer])

    set_status(:Z, @registers[:a] == 0x00)
    set_status(:N, @registers[:a] & 0x80)
    0
  end

  def PLP()
    @registers[:stack_pointer] += 1

    @registers[:status] = @bus.read(0x0100 + @registers[:stack_pointer])
    set_status(:U, 1)

    0
 end

  def ROL()
    fetch

    temp = @fetched << 1 | get_status(:C)
    set_status(:C, temp & 0x00FF)
    set_status(:Z, (temp & 0x00FF) == 0x00)
    set_status(:N, temp & 0x80)

    if @lookup[@opcode][:addr_mode].equal? self.IMP
      @registers[:a] = temp & 0x00FF
    else
      @bus.write(@addr_abs, temp & 0x00FF)
    end
    0
  end

  def ROR()
    fetch

    temp = get_status(:C) << 7 | @fetched >> 1
    set_status(:C, @fetched & 0x01)
    set_status(:Z, (temp & 0x00FF) == 0x00)
    set_status(:N, temp & 0x80)

    if @lookup[@opcode][:addr_mode].equal? self.IMP
      @registers[:a] = temp & 0x00FF
    else
      @bus.write(@addr_abs, temp & 0x00FF)
    end

    0
  end

  def RTI()
    @registers[:stack_pointer] += 1
    @registers[:status] = @bus.read(0x0100 + @registers[:stack_pointer])
    @registers[:status] &= ~@flags[:B]
    @registers[:status] &= ~@flags[:U]

    @registers[:stack_pointer] += 1
    @registers[:program_counter] = @bus.read(0x0100 + @registers[:stack_pointer])
    @registers[:stack_pointer] += 1

    @registers[:program_counter] |= @bus.read(0x0100 + @registers[:stack_pointer]) << 8

    0
  end

  def RTS()
    @registers[:stack_pointer] += 1

    @registers[:program_counter] = @bus.read(0x0100 + @registers[:stack_pointer])

    @registers[:stack_pointer] += 1

    @registers[:program_counter] |= @bus.read(0x0100 + @registers[:stack_pointer]) << 8

    0
  end

  def SEC()
    set_status(:C, true)

    0
  end

  def SED()
    set_status(:D, true)

    0
  end

  def SEI()
    set_status(:I, true)

    0
  end

  def STA()
    @bus.write(@addr_abs, @registers[:a])

    0
  end

  def STX()
    @bus.write(@addr_abs, @registers[:x])

    0
  end

  def STY()
    @bus.write(@addr_abs, @registers[:y])

    0
  end

  def TAX()
    a = @registers[:a]

    @registers[:x] = a

    set_status(:Z, a == 0x00)
    set_status(:N, a & 0x80)

    0
  end

  def TAY()
    a = @registers[:a]

    @registers[:y] = a

    set_status(:Z, a == 0x00)
    set_status(:N, a & 0x00)

    0
  end

  def TSX()
    stack_pointer = @registers[:stack_pointer]

    @registers[:x] = stack_pointer

    set_status(:Z, stack_pointer == 0x00)
    set_status(:N, a & 0x00)

    0
  end

  def TXA()
    x = @registers[:x]

    @registers[:a] = x

    set_status(:Z, x == 0x00)
    set_status(:N, x & 0x80)

    0
  end

  def TXS()
    x = @registers[:x]

    @registers[:stack_pointer] = x

    set_status(:Z, x == 0x00)
    set_status(:N, x & 0x80)

    0
  end

  def TYA()
    y = @registers[:y]

    @registers[:a] = y

    set_status(:Z, y == 0x00)
    set_status(:N, y & 0x80)

    0
  end

  def INVALID()
    0
  end

  # ---- END OPCODES ----

  def clock
    if (@cycles == 0)
      @opcode = @bus.read(@registers[:program_counter])

      puts "[ #{@opcode.to_s(16).upcase} ] $#{@opcode} -> #{@lookup[@opcode][:name]}"

      set_status(:U, 1)

      @registers[:program_counter] += 1

      @cycles = @lookup[@opcode][:cycles]

      clock_cycle = @lookup[@opcode][:addr_mode].call
      clock_cycle2 = @lookup[@opcode][:operate].call

      @cycles += (clock_cycle & clock_cycle2)

      set_status(:U, 1)
    end

    @cycles -= 1
  end

  # ---- Interruptions ----
  def reset
    @registers[:a] = 0x00
    @registers[:x] = 0x00
    @registers[:y] = 0x00
    @registers[:stack_pointer] = 0xFD
    @registers[:status] = 0x00 | @flags[:U]

    @addr_abs = 0xFFFC
    low = @bus.read(@addr_abs)
    high = @bus.read(@addr_abs + 1)

    @registers[:program_counter] = (high << 8) | low;
    @addr_abs = 0x0000
    @fetched = 0x00

    @cycles = 8
  end

  def irq
    if(get_status(:I) == 0)
      @bus.write(0x0100 + @registers[:stack_pointer], (@registers[:program_counter] > 8) & 0x00FF)
      @registers[:stack_pointer] -= 1

      @bus.write(0x0100 + @registers[:stack_pointer], @registers[:program_counter] & 0x00FF)
      @registers[:stack_pointer] -= 1

      set_status(:B, 0)
      set_status(:U, 1)
      set_status(:I, 1)
      @bus.write(0x0100 + @registers[:stack_pointer], @registers[:status])
      @registers[:stack_pointer] -= 1

      @addr_abs = 0xFFFE;
      low = @bus.read(@addr_abs + 0);
      high = @bus.read(@addr_abs + 1);
      @registers[:program_counter] = (high << 8) | low;

      cycles = 7;

    end
  end

  def nmi
    @bus.write(0x0100 + @registers[:stack_pointer], (@registers[:program_counter] > 8) & 0x00FF)
    @registers[:stack_pointer] -= 1

    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:program_counter] & 0x00FF)
    @registers[:stack_pointer] -= 1

    set_status(:B, 0)
    set_status(:U, 1)
    set_status(:I, 1)
    @bus.write(0x0100 + @registers[:stack_pointer], @registers[:status])
    @registers[:stack_pointer] -= 1

    @addr_abs = 0xFFFE;
    low = @bus.read(@addr_abs + 0);
    high = @bus.read(@addr_abs + 1);
    @registers[:program_counter] = (high << 8) | low;

    cycles = 8;
  end

  def fetch
    if !(@lookup[@opcode][:addr_mode].equal? self.IMP)
      @fetched = @bus.read(@addr_abs)
    end

    @fetched
  end


  def set_status(flag, v) #setFlag
    if v != 0 && v != false
      @registers[:status] |= @flags[flag]
    else
      @registers[:status] &= ~@flags[flag]
    end
  end

  def get_status(flag)
    ((@registers[:status] & @flags[flag]) > 0) ? 1 : 0;
  end

  def complete()
    return @cycles == 0
  end
end
