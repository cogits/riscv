//! control and status register
const csr = @This();
const std = @import("std");

const Register = enum {
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
    /// Machine Integerrupt Pending
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
    };

    pub const set = struct {
        pub fn mpp(value: Mpp) void {
            // reset to 0
            clear(.mstatus, .{ .mpp = .machine });
            // set mpp
            csr.set(.mstatus, .{ .mpp = value });
        }
    };
};

/// Machine cause register
pub const mcause = xcause;

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
pub const scause = xcause;

const xcause = packed struct(usize) {
    code: XlenMinus(1) = 0,
    interrupt: bool = false,

    pub fn getCode(self: xcause) Code {
        return if (self.interrupt)
            .{ .interrupt = @enumFromInt(self.code) }
        else
            .{ .exception = @enumFromInt(self.code) };
    }

    pub const Code = union(enum) {
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

    pub fn format(cause: xcause, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (cause.getCode()) {
            // If the non-exhaustive enum value does not map to a name, it invokes safety-checked Undefined Behavior.
            inline else => |value| try writer.print("{s}", .{@tagName(value)}),
        }
    }
};

pub const raw = struct {
    pub fn read(comptime tag: Register) RegisterBits(tag) {
        const name = @tagName(tag);
        return asm volatile ("csrr %[ret], " ++ name
            : [ret] "=r" (-> RegisterBits(tag)),
        );
    }

    pub fn write(comptime tag: Register, value: RegisterBits(tag)) void {
        const name = @tagName(tag);
        asm volatile ("csrw " ++ name ++ ", %[value]"
            :
            : [value] "r" (value),
        );
    }

    pub fn set(comptime tag: Register, mask: RegisterBits(tag)) void {
        const name = @tagName(tag);
        asm volatile ("csrs " ++ name ++ ", %[mask]"
            :
            : [mask] "r" (mask),
        );
    }

    pub fn clear(comptime tag: Register, mask: RegisterBits(tag)) void {
        const name = @tagName(tag);
        asm volatile ("csrc " ++ name ++ ", %[mask]"
            :
            : [mask] "r" (mask),
        );
    }
};

fn RegisterType(comptime tag: Register) type {
    return @field(csr, @tagName(tag));
}

fn RegisterBits(comptime tag: Register) type {
    return if (@hasDecl(csr, @tagName(tag)))
        std.meta.Int(.unsigned, @bitSizeOf(RegisterType(tag)))
    else
        usize;
}

pub fn read(comptime tag: Register) RegisterType(tag) {
    return @bitCast(raw.read(tag));
}

pub fn set(comptime tag: Register, register: RegisterType(tag)) void {
    raw.set(tag, @bitCast(register));
}

pub fn clear(comptime tag: Register, register: RegisterType(tag)) void {
    raw.clear(tag, @bitCast(register));
}

fn XlenMinus(n: u16) type {
    return std.meta.Int(.unsigned, @bitSizeOf(usize) - n);
}
