/// control and status register
pub const csr = enum {
    /// Hart ID
    mhartid,
    /// Machine Status
    mstatus,
    /// Machine Trap Vector Base Address
    mtvec,
    /// Machine Exception Delegation
    medeleg,
    /// Machine Interrupt Delegation
    mideleg,
    /// Machine Interrupt Pending
    mip,
    /// Machine Interrupt Enable
    mie,
    /// Machine Counter Enable
    mcounteren,
    /// Machine Scratch
    mscratch,
    /// Machine Exception Program Counter
    mepc,
    /// Machine Cause
    mcause,
    /// Machine Trap Value
    mtval,
    /// Machine Environment Configuration
    menvcfg,
    /// read-only shadow of the memory-mapped mtime register
    time,
    /// Machine Timer
    mtime,
    /// Machine Timer Compare
    mtimecmp,
    /// Machine Trap Return
    mret,
    /// PMP configuration registers
    pmpcfg0,
    /// PMP address registers
    pmpaddr0,

    /// Supervisor Status
    sstatus,
    /// Supervisor Trap Vector Base Address
    stvec,
    /// Supervisor Interrupt Pending
    sip,
    /// Supervisor Interrupt Enable
    sie,
    /// Supervisor Couunter Enable
    scounteren,
    /// Supervisor Scratch
    sscratch,
    /// Supervisor Exception Program Counter
    sepc,
    /// Supervisor Cause
    scause,
    /// Supervisor Trap Value
    stval,
    /// Supervisor Environment Configuration
    senvcfg,
    /// Supervisor Address Translation and Protection
    satp,
    /// Supervisor Timer
    stimecmp,

    /// Reads the current value of the specified CSR.
    /// Returns the value as the register's corresponding type.
    pub fn read(comptime tag: csr) Type(tag) {
        return @bitCast(raw.read(tag));
    }

    /// Writes a new value to the specified CSR.
    /// Note: This overwrites the entire register contents.
    pub fn write(comptime tag: csr, register: Type(tag)) void {
        raw.write(tag, @bitCast(register));
    }

    /// Sets (ORs) bits in the CSR specified by the mask.
    /// Only bits set to 1 in the mask will be set in the CSR.
    pub fn set(comptime tag: csr, register: Type(tag)) void {
        raw.set(tag, @bitCast(register));
    }

    /// Clears bits in the CSR specified by the mask.
    /// Only bits set to 1 in the mask will be cleared in the CSR.
    pub fn clear(comptime tag: csr, register: Type(tag)) void {
        raw.clear(tag, @bitCast(register));
    }

    /// Direct CSR operations using raw integer values.
    /// These bypass type safety and work directly with the underlying machine words.
    const raw = struct {
        fn read(comptime tag: csr) Int(tag) {
            const name = @tagName(tag);
            return asm volatile ("csrr %[ret], " ++ name
                : [ret] "=r" (-> Int(tag)),
            );
        }

        fn write(comptime tag: csr, value: Int(tag)) void {
            const name = @tagName(tag);
            asm volatile ("csrw " ++ name ++ ", %[value]"
                :
                : [value] "r" (value),
            );
        }

        fn set(comptime tag: csr, mask: Int(tag)) void {
            const name = @tagName(tag);
            asm volatile ("csrs " ++ name ++ ", %[mask]"
                :
                : [mask] "r" (mask),
            );
        }

        fn clear(comptime tag: csr, mask: Int(tag)) void {
            const name = @tagName(tag);
            asm volatile ("csrc " ++ name ++ ", %[mask]"
                :
                : [mask] "r" (mask),
            );
        }
    };

    /// Returns the type-safe wrapper for a CSR if defined, otherwise returns the raw integer type.
    pub fn Type(comptime tag: csr) type {
        const name = @tagName(tag);
        return if (@hasDecl(top, name)) @field(top, name) else Int(tag);
    }

    /// Returns the appropriate unsigned integer type for raw CSR operations.
    /// Uses the bit size of the CSR's type if defined, otherwise falls back to usize.
    pub fn Int(comptime tag: csr) type {
        return if (@hasDecl(top, @tagName(tag)))
            std.meta.Int(.unsigned, @bitSizeOf(Type(tag)))
        else
            usize;
    }
};

/// Machine Status Register
pub const mstatus = packed struct(usize) {
    @"0": u1 = 0,
    sie: bool = false,

    @"2": u1 = 0,
    mie: bool = false,

    @"4": u1 = 0,
    spie: bool = false,
    ube: bool = false,
    mpie: bool = false,
    spp: bool = false,
    vs: u2 = 0,
    mpp: Mpp = .user,

    _: XlenMinus(13) = 0,

    pub const Mpp = enum(u2) {
        user = 0b00,
        supervisor = 0b01,
        hypervisor = 0b10,
        machine = 0b11,

        /// Use this to CLEAR the field
        pub const clear_mask: Mpp = .machine;
    };
};

/// Machine cause register
pub const mcause = cause;

/// Supervisor Status Register
pub const sstatus = packed struct(usize) {
    @"0": u1 = 0,
    sie: bool = false,

    @"2-4": u3 = 0,
    spie: bool = false,
    ube: bool = false,

    @"7": u1 = 0,
    spp: bool = false,

    _: XlenMinus(9) = 0,
};

pub const menvcfg = packed struct(u64) {
    fiom: bool = false,
    @"1-3": u3 = 0,

    cbie: u2 = 0,
    cbcfe: bool = false,
    cbze: bool = false,

    @"8-31": u24 = 0,
    pmm: u2 = 0,

    @"34-59": u26 = 0,
    cde: bool = false,
    adue: bool = false,
    pbmte: bool = false,
    stce: bool = false,
};

pub const mcounteren = packed struct(u32) {
    cy: bool = false,
    tm: bool = false,
    ir: bool = false,
    hpm: u29 = 0,
};

/// Machine-mode Interrupt Enable
pub const mie = packed struct(usize) {
    @"0": u1 = 0,
    ssie: bool = false,

    @"2": u1 = 0,
    msie: bool = false,

    @"4": u1 = 0,
    stie: bool = false,

    @"6": u1 = 0,
    mtie: bool = false,

    @"8": u1 = 0,
    seie: bool = false,

    @"10": u1 = 0,
    meie: bool = false,

    _: XlenMinus(12) = 0,
};

/// Supervisor interrupt-pending register
pub const sip = packed struct(usize) {
    usip: bool = false,
    ssip: bool = false,

    @"2-3": u2 = 0,
    utip: bool = false,
    stip: bool = false,

    @"6-7": u2 = 0,
    ueip: bool = false,
    seip: bool = false,

    _: XlenMinus(10) = 0,
};

/// Supervisor Interrupt Enable
pub const sie = packed struct(usize) {
    @"0": u1 = 0,
    ssie: bool = false,

    @"2-4": u3 = 0,
    stie: bool = false,

    @"6-8": u3 = 0,
    seie: bool = false,

    _: XlenMinus(10) = 0,
};

/// Supervisor Address Translation and Protection Register
pub const satp = if (@bitSizeOf(usize) == 32) satp32 else satp64;

const satp32 = packed struct(u32) {
    /// Physical Page Number
    ppn: u22 = 0,

    /// Address Space Identifier (optional)
    asid: u9 = 0,

    mode: enum(u1) {
        none = 0,
        sv32 = 1,
    } = .none,
};

const satp64 = packed struct(u64) {
    /// Physical Page Number
    ppn: u44 = 0,

    /// Address Space Identifier (optional)
    asid: u16 = 0,

    mode: enum(u4) {
        none = 0,
        sv39 = 8,
        sv48 = 9,
    } = .none,
};

/// Supervisor cause register
pub const scause = cause;

const cause = packed struct(usize) {
    code: Code,
    interrupt: bool = false,

    pub const Code = packed union {
        interrupt: Interrupt,
        exception: Exception,
    };

    pub const Interrupt = enum(XlenMinus(1)) {
        @"User software interrupt" = 0,
        @"Supervisor software interrupt" = 1,
        @"Machine software interrupt" = 3,

        @"User timer interrupt" = 4,
        @"Supervisor timer interrupt" = 5,
        @"Machine timer interrupt" = 7,

        @"User external interrupt" = 8,
        @"Supervisor external interrupt" = 9,
        @"Machine external interrupt" = 11,

        _,
    };

    pub const Exception = enum(XlenMinus(1)) {
        @"Instruction address misaligned" = 0,
        @"Instruction address fault" = 1,
        @"Illegal instruction" = 2,
        Breakpoint = 3,
        @"Load address misaligned" = 4,
        @"Load access fault" = 5,
        @"Store/AMO address misaligned" = 6,
        @"Store/AMO access fault" = 7,
        @"Environment call from U-mode" = 8,
        @"Environment call from S-mode" = 9,

        @"Environment call from M-mode" = 11,
        @"Instruction page fault" = 12,
        @"Load page fault" = 13,

        @"Store/AMO page fault" = 15,

        _,
    };

    pub fn format(self: cause, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        // If the non-exhaustive enum value does not map to a name, it invokes safety-checked Undefined Behavior.
        if (self.interrupt) {
            try writer.print("{s}", .{@tagName(self.code.interrupt)});
        } else {
            try writer.print("{s}", .{@tagName(self.code.exception)});
        }
    }
};

fn XlenMinus(n: u16) type {
    return std.meta.Int(.unsigned, @bitSizeOf(usize) - n);
}

const std = @import("std");
const top = @This();
