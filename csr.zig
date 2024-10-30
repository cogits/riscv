//! control and status register
const csr = @This();
const std = @import("std");

const Register = enum {
    mhartid,
    mscratch,
    mstatus,
    mepc,
    mtvec,
    mip,
    mie,
    medeleg,
    mideleg,
    mret,
    mcause,

    sstatus,
    satp,
    sie,
    sip,
    scause,
    stvec,
    stval,
    sepc,

    pmpaddr0,
    pmpcfg0,
};

comptime {
    for (std.meta.fields(Register)) |field| {
        if (@hasDecl(csr, field.name)) {
            const S = @field(csr, field.name);
            // All the following packed structs must be 64bit.
            std.debug.assert(@bitSizeOf(S) == 64);
        }
    }
}

/// Machine Status Register
pub const mstatus = packed struct {
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

    _: u51 = 0,

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
pub const sstatus = packed struct {
    @"0": u1 = 0,
    sie: bool = false,

    @"2-4": u3 = 0,
    spie: bool = false,
    ube: bool = false,

    @"7": u1 = 0,
    spp: bool = false,

    _: u55 = 0,
};

/// Machine-mode Interrupt Enable
pub const mie = packed struct {
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

    _: u52 = 0,
};

/// Supervisor interrupt-pending register
pub const sip = packed struct {
    usip: bool = false,
    ssip: bool = false,

    @"2-3": u2 = 0,
    utip: bool = false,
    stip: bool = false,

    @"6-7": u2 = 0,
    ueip: bool = false,
    seip: bool = false,

    _: u54 = 0,
};

/// Supervisor Interrupt Enable
pub const sie = packed struct {
    @"0": u1 = 0,
    ssie: bool = false,

    @"2-4": u3 = 0,
    stie: bool = false,

    @"6-8": u3 = 0,
    seie: bool = false,

    _: u54 = 0,
};

/// Supervisor Address Translation and Protection Register
pub const satp = packed struct {
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

const xcause = packed struct {
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
            inline else => |value| {
                // The enum is non-exhaustive. We can't use @tagName here.
                const T = @TypeOf(value);
                inline for (std.meta.fields(T)) |field| {
                    if (field.value == @intFromEnum(value)) {
                        try writer.print("{s}", .{field.name});
                        break;
                    }
                } else try writer.print("{s}: {d}", .{
                    if (T == Interrupt) "Interrupt" else "Exception",
                    @intFromEnum(value),
                });
            },
        }
    }
};

pub const raw = struct {
    pub fn read(comptime register: Register) usize {
        const name = @tagName(register);
        return asm volatile ("csrr %[ret], " ++ name
            : [ret] "=r" (-> usize),
        );
    }

    pub fn write(comptime register: Register, value: usize) void {
        const name = @tagName(register);
        asm volatile ("csrw " ++ name ++ ", %[value]"
            :
            : [value] "r" (value),
        );
    }

    pub fn set(comptime register: Register, mask: usize) void {
        const name = @tagName(register);
        asm volatile ("csrs " ++ name ++ ", %[mask]"
            :
            : [mask] "r" (mask),
        );
    }

    pub fn clear(comptime register: Register, mask: usize) void {
        const name = @tagName(register);
        asm volatile ("csrc " ++ name ++ ", %[mask]"
            :
            : [mask] "r" (mask),
        );
    }
};

fn RegisterType(comptime tag: Register) type {
    return @field(csr, @tagName(tag));
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
