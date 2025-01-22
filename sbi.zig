//! supervisor binary interface
pub const Extension = enum(i32) {
    /// Debug Console Extension
    debug = 0x4442_434E,
    /// System Reset Extension
    reset = 0x5352_5354,
    /// Timer Extension
    timer = 0x5449_4D45,

    _,

    /// Doing a SBI ecall
    fn call(ext: Extension, fid: i32, args: [6]usize) !usize {
        const eid: i32 = @intFromEnum(ext);
        var err: isize = 0;
        var val: usize = 0;

        asm volatile ("ecall"
            : [ret] "={x10}" (err), // err a0
              [val] "={x11}" (val), // val a1
            : [eid] "{x17}" (eid), // a7 for EID
              [fid] "{x16}" (fid), // a6 for FID
              [arg0] "{x10}" (args[0]),
              [arg1] "{x11}" (args[1]),
              [arg2] "{x12}" (args[2]),
              [arg3] "{x13}" (args[3]),
              [arg4] "{x14}" (args[4]),
              [arg5] "{x15}" (args[5]),
        );

        return switch (err) {
            0 => val,
            -1 => error.failed,
            -2 => error.not_supported,
            -3 => error.invalid_param,
            -4 => error.denied,
            -5 => error.invalid_address,
            -6 => error.already_available,
            -7 => error.already_started,
            -8 => error.already_stopped,
            -9 => error.no_shared_memory,
            -10 => error.invalid_state,
            -11 => error.bad_range,
            -12 => error.timeout,
            -13 => error.io,
            else => unreachable,
        };
    }
};

pub fn putChar(char: u8) void {
    _ = Extension.debug.call(2, .{ char, 0, 0, 0, 0, 0 }) catch unreachable;
}

pub fn putString(string: []const u8) usize {
    return Extension.debug.call(0, .{ string.len, @intFromPtr(string.ptr), 0, 0, 0, 0 }) catch unreachable;
}

pub fn setTimer(value: usize) void {
    _ = Extension.timer.call(0, .{ value, 0, 0, 0, 0, 0 }) catch unreachable;
}

pub fn shutdown(
    @"type": enum(u32) { shutdown = 0x0, cold_reboot = 0x1, warm_reboot = 0x2, _ },
    reason: enum(u32) { no_reason = 0x0, system_failure = 0x1, _ },
) noreturn {
    _ = Extension.reset.call(0, .{ @intFromEnum(@"type"), @intFromEnum(reason), 0, 0, 0, 0 }) catch unreachable;
    unreachable;
}
