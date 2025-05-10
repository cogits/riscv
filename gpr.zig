/// general-purpose register
pub const gpr = enum {
    // zig fmt: off

    /// Hard-wired zero
    x0,
    /// Return address
    x1,
    /// Stack pointer
    x2,
    /// Global pointer
    x3,
    /// Thread pointer
    x4,
    // Temporaries
    x5, x6, x7,
    /// Saved register/frame pointer
    x8,
    /// Saved register
    x9,
    // Function arguments/return values
    x10, x11,
    // Function arguments
    x12, x13, x14, x15, x16, x17,
    // Saved registers
    x18, x19, x20, x21, x22, x23, x24, x25, x26, x27,
    // Temporaries
    x28, x29, x30, x31,

    // zig fmt: on

    /// Hard-wired zero
    pub const zero: gpr = .x0;
    /// Return address
    pub const ra: gpr = .x1;
    /// Stack pointer
    pub const sp: gpr = .x2;
    /// Global pointer
    pub const gp: gpr = .x3;
    /// Thread pointer
    pub const tp: gpr = .x4;

    // Temporaries
    pub const t0: gpr = .x5;
    pub const t1: gpr = .x6;
    pub const t2: gpr = .x7;
    // Saved register/frame pointer
    pub const s0: gpr = .x8;
    pub const fp: gpr = .x8;
    // Saved register
    pub const s1: gpr = .x9;
    // Function arguments/return values
    pub const a0: gpr = .x10;
    pub const a1: gpr = .x11;

    // Function arguments
    pub const a2: gpr = .x12;
    pub const a3: gpr = .x13;
    pub const a4: gpr = .x14;
    pub const a5: gpr = .x15;
    pub const a6: gpr = .x16;
    pub const a7: gpr = .x17;

    // Saved registers
    pub const s2: gpr = .x18;
    pub const s3: gpr = .x19;
    pub const s4: gpr = .x20;
    pub const s5: gpr = .x21;
    pub const s6: gpr = .x22;
    pub const s7: gpr = .x23;
    pub const s8: gpr = .x24;
    pub const s9: gpr = .x25;
    pub const s10: gpr = .x26;
    pub const s11: gpr = .x27;

    // Temporaries
    pub const t3: gpr = .x28;
    pub const t4: gpr = .x29;
    pub const t5: gpr = .x30;
    pub const t6: gpr = .x31;

    pub fn read(comptime register: gpr) usize {
        const name = @tagName(register);
        return asm volatile ("mv %[ret], " ++ name
            : [ret] "=r" (-> usize),
        );
    }

    pub fn write(comptime register: gpr, value: usize) void {
        const name = @tagName(register);
        asm volatile ("mv " ++ name ++ ", %[value]"
            :
            : [value] "r" (value),
        );
    }
};
