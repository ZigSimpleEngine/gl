//! Sampler objects: sampling state independent of a specific texture.
//!
//! A sampler encapsulates the filtering and wrapping state that is normally
//! stored inside the texture. Multiple textures can be sampled through the
//! same sampler, which allows reusing one configuration for many textures.

const loader = @import("loader.zig");
const textures = @import("textures.zig");

/// Sampling parameter of a sampler object. The semantics of each value are
/// identical to [`textures.TextureParameter`](textures.TextureParameter).
pub const SamplerParameter = textures.TextureParameter;

/// Generates `count` new sampler names (port of `glGenSamplers`).
///
/// Sampler names do not become samplers until first bound.
///
/// ```
/// var sampler: u32 = 0;
/// gl.samplers.gen(1, &sampler);
/// ```
pub fn gen(count: i32, samplers: [*]u32) void {
    loader.context.gen_samplers(count, samplers);
}

/// Deletes the given samplers (port of `glDeleteSamplers`).
pub fn delete(count: i32, samplers: [*]const u32) void {
    loader.context.delete_samplers(count, samplers);
}

/// Returns whether `sampler` is the name of an existing sampler
/// (port of `glIsSampler`).
pub fn isSampler(sampler: u32) bool {
    return loader.context.isSampler(sampler) != 0;
}

/// Binds the sampler to the given texture unit (port of `glBindSampler`).
///
/// The unit index matches the one used by
/// [`textures.activeTexture`](textures.activeTexture).
pub fn bind(unit: u32, sampler: u32) void {
    loader.context.bind_sampler(unit, sampler);
}

/// Sets an integer-valued parameter of the sampler (port of
/// `glSamplerParameteri`).
///
/// ```
/// gl.samplers.parameterI(sampler, .texture_min_filter, @intFromEnum(.linear_mipmap_linear));
/// ```
pub fn parameterI(sampler: u32, pname: SamplerParameter, param: i32) void {
    loader.context.sampler_parameter_i(sampler, @intFromEnum(pname), param);
}

/// Sets a floating-point parameter of the sampler (port of
/// `glSamplerParameterf`).
pub fn parameterF(sampler: u32, pname: SamplerParameter, param: f32) void {
    loader.context.sampler_parameter_f(sampler, @intFromEnum(pname), param);
}

/// Sets an array of integer parameters of the sampler (port of
/// `glSamplerParameteriv`).
pub fn parameterIv(sampler: u32, pname: SamplerParameter, param: [*]const i32) void {
    loader.context.sampler_parameter_iv(sampler, @intFromEnum(pname), param);
}

/// Sets an array of floating-point parameters of the sampler (port of
/// `glSamplerParameterfv`).
pub fn parameterFv(sampler: u32, pname: SamplerParameter, param: [*]const f32) void {
    loader.context.sampler_parameter_fv(sampler, @intFromEnum(pname), param);
}

/// Reads an integer-valued parameter of the sampler (port of
/// `glGetSamplerParameteriv`).
pub fn getParameterI(sampler: u32, pname: SamplerParameter, params: [*]i32) void {
    loader.context.get_sampler_parameter_iv(sampler, @intFromEnum(pname), params);
}

/// Reads a floating-point parameter of the sampler (port of
/// `glGetSamplerParameterfv`).
pub fn getParameterF(sampler: u32, pname: SamplerParameter, params: [*]f32) void {
    loader.context.get_sampler_parameter_fv(sampler, @intFromEnum(pname), params);
}