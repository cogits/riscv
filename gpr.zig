//! general-purpose register
const Register = enum {
    // zig fmt: off

    /// Hard-wired zero
    zero,
    /// Return address
    ra,
    /// Stack pointer
    sp,
    /// Global pointer
    gp,
    /// Thread pointer
    tp,
    /// Temporary/alternate link register
    t0,
    /// Temporaries
    t1, t2,
    /// Saved register/frame pointer
    s0,
    /// Saved register
    s1,
    /// Function arguments/return values
    a0, a1,
    /// Function arguments
    a2, a3, a4, a5, a6, a7,
    /// Saved registers
    s2, s3, s4, s5, s6, s7, s8, s9, s10, s11,
    /// Temporaries
    t3, t4, t5, t6,

    // zig fmt: on

    // aliases
    /// Saved register/frame pointer
    const fp: @This() = .s0;
};

pub fn read(comptime register: Register) usize {
    const name = @tagName(register);
    return asm volatile ("mv %[ret], " ++ name
        : [ret] "=r" (-> usize),
    );
}

pub fn write(comptime register: Register, value: usize) void {
    const name = @tagName(register);
    asm volatile ("mv " ++ name ++ ", %[value]"
        :
        : [value] "r" (value),
    );
}
