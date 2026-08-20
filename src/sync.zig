//! Sync objects: CPU-GPU synchronization primitives.
//!
//! A sync object is a fence inserted into the GPU command stream. The CPU
//! can wait on it ([`clientWait`](clientWait), [`wait`](wait)) or query
//! its status without blocking ([`getParameter`](getParameter)),
//! which is the recommended way to pair asynchronous uploads with draws.

const loader = @import("loader.zig");
const types = @import("types.zig");

/// Condition defining when a fence is signaled
/// (`GL_SYNC_GPU_COMMANDS_COMPLETE`).
pub const FenceCondition = enum(u32) {
    /// The fence is signaled when all previously issued commands have
    /// completed on the GPU (`GL_SYNC_GPU_COMMANDS_COMPLETE`).
    sync_gpu_commands_complete = 0x9117,
};

/// Status of a sync object (`GL_SIGNALED`, `GL_UNSIGNALED`).
pub const SyncStatus = enum(u32) {
    /// The sync object is signaled (`GL_SIGNALED`).
    signaled = 0x9119,

    /// The sync object is not signaled yet (`GL_UNSIGNALED`).
    unsignaled = 0x9118,
};

/// A parameter of a sync object read via [`getParameter`](getParameter).
pub const SyncParameter = enum(u32) {
    /// Type of the sync object (`GL_OBJECT_TYPE`; always `GL_SYNC_FENCE`
    /// for fences).
    object_type = 0x9112,

    /// Condition of the sync object
    /// ([`FenceCondition`](FenceCondition), `GL_SYNC_CONDITION`).
    sync_condition = 0x9113,

    /// Status of the sync object ([`SyncStatus`](SyncStatus),
    /// `GL_SYNC_STATUS`).
    sync_status = 0x9114,

    /// Flags the fence was created with (`GL_SYNC_FLAGS`, see
    /// [`sync_flush_commands_bit`](sync_flush_commands_bit)).
    sync_flags = 0x9115,
};

/// Result of [`clientWait`](clientWait).
pub const WaitResult = enum(u32) {
    /// The sync object is already signaled (`GL_ALREADY_SIGNALED`).
    already_signaled = 0x911A,

    /// The timeout elapsed before the sync object was signaled
    /// (`GL_TIMEOUT_EXPIRED`).
    timeout_expired = 0x911B,

    /// The sync object was signaled within the timeout
    /// (`GL_CONDITION_SATISFIED`).
    condition_satisfied = 0x911C,

    /// The wait failed due to an error (`GL_WAIT_FAILED`).
    wait_failed = 0x911D,
};

/// Flag passed to [`fence`](fence): flush pending commands before the fence
/// is inserted (`GL_SYNC_FLUSH_COMMANDS_BIT`).
pub const sync_flush_commands_bit: u32 = 0x00000001;

/// Special timeout value for [`wait`](wait): block indefinitely
/// (`GL_TIMEOUT_IGNORED`).
pub const timeout_ignored: u64 = 0xFFFFFFFFFFFFFFFF;

/// Inserts a fence into the command stream and returns its sync object
/// (port of `glFenceSync`).
///
/// The object must be released with [`delete`](delete) when no longer
/// needed.
///
/// ```
/// const fence = gl.sync.fence(.sync_gpu_commands_complete, 0);
/// defer gl.sync.delete(fence);
/// ```
pub fn fence(condition: FenceCondition, flags: u32) types.Sync {
    return loader.context.fence_sync(@intFromEnum(condition), flags);
}

/// Deletes the sync object (port of `glDeleteSync`).
///
/// Deletion is deferred while the fence is still pending; the object becomes
/// unusable immediately, though.
pub fn delete(sync_obj: types.Sync) void {
    loader.context.delete_sync(sync_obj);
}

/// Returns whether `sync_obj` is the name of an existing sync object (port
/// of `glIsSync`).
pub fn isSync(sync_obj: types.Sync) bool {
    return loader.context.isSync(sync_obj) != 0;
}

/// Reads a parameter of the sync object (port of `glGetSynciv`).
///
/// `count` is the number of integers that can be stored into `values`; the
/// number actually written is reported through `length` (may be `null`).
pub fn getParameter(
    sync_obj: types.Sync,
    pname: SyncParameter,
    count: i32,
    length: ?*i32,
    values: [*]i32,
) void {
    loader.context.get_sync_iv(sync_obj, @intFromEnum(pname), count, length, values);
}

/// Blocks the CPU until the sync object is signaled or the timeout in
/// nanoseconds elapses (port of `glClientWaitSync`).
///
/// The status is returned as a [`WaitResult`](WaitResult). A non-blocking
/// check is done by passing `0` as `timeout_ns`.
///
/// ```
/// const status = gl.sync.clientWait(fence, 0, timeout_ns);
/// if (status == .condition_satisfied) { ... }
/// ```
pub fn clientWait(sync_obj: types.Sync, flags: u32, timeout_ns: u64) WaitResult {
    return @enumFromInt(loader.context.client_wait_sync(sync_obj, flags, timeout_ns));
}

/// Blocks the CPU until the sync object is signaled (port of `glWaitSync`).
///
/// Unlike [`clientWait`](clientWait) this form returns no status; it
/// blocks without limit. Prefer [`clientWait`](clientWait) with an
/// explicit timeout where possible.
pub fn wait(sync_obj: types.Sync, flags: u32, timeout_ns: u64) void {
    loader.context.wait_sync(sync_obj, flags, timeout_ns);
}