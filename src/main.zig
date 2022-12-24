const glfw = @cImport(@cInclude("GLFW/glfw3.h"));
const gl = @import("dep/zgl/zgl.zig");
const inotify = @cImport(@cInclude("sys/inotify.h"));
const std = @import("std");

const Shader = struct {
    id: gl.Program,
    // location of "u_time" uniform (if used)
    u_time: ?u32,
};

//const ro: f32 = 1.0; // density
//const n: usize = 100;
//const o: f32 = 1.9; // overrelaxation
//const h: f32 = 1.0; // height of each cell

// XXX: take into account that the grid has a border of zeroed cells.

//fn update(v: []f32, u: []f32, s: []f32, p: []f32, width: usize, height: usize, dt: f32) void {
//    // Update downward velocities
//    for (v) |*vv| vv += -9.81 * dt;
//
//    for (p) |*pp| pp = 0;
//
//    var i: usize = 1;
//
//    while (i < width) : (i += 1) {
//        var j: usize = 1;
//        while (j < height) : (j += 1) {
//            {
//                // pretend there's a wall on the borders
//                const vup = v[(i - 1) * width + j];
//                const vdown = v[i * width + j];
//                const uleft = u[i * width + j];
//                const uright = u[i * width + j + 1];
//
//                // compute divergence
//                const div = o * (uright - uleft + vup - vdown);
//
//                const sc = s[(i - 1) * width + j] + s[(i + 1) * width + j] + s[
//                    i *
//                        width + j - 1
//                ] + s[i * width + j + 1];
//                // force incompressibility
//                v[(i - 1) * width + j] = div / sc;
//                u[i * width + j + 1] = div / sc;
//                v[i * width + j] += div / sc;
//                u[i * width + j] += div / sc;
//
//                // compute pressure
//                p[i * width + j] += div / sc * ro * h / dt;
//            }
//
//            // advection
//            // compute v at position x where u is stored
//            {
//                // the particle that got here.
//                const xu = @intToFloat(f32, i) - dt * u[i * width + j];
//                const xv = @intToFloat(f32, j) - dt * v[i * width + j];
//
//                // the cell location of the particle that got here.
//                const ci = @floatToInt(usize, std.math.clamp(xu, 0.0, @intToFloat(f32, width - 1)));
//                const ck = @floatToInt(usize, std.math.clamp(xv, 0.0, @intToFloat(f32, height - 1)));
//
//                // x = distance from xu to start of cell + half cell
//                const x = xu - @intToFloat(f32, ci) + h / 2;
//                // y = distance from xv to bottom of cell
//                const y = xv + 1 - @intToFloat(f32, ck);
//
//                const w00 = 1 - x / h;
//                const w10 = 1 - y / h;
//                const w01 = x / h;
//                const w11 = y / h;
//
//                // the corresponding upward velocity
//                const vu = u[ci * width + ck];
//                const vv = w00 * w10 * v[ci * width + ck] + w10 * w11 * v[(ci - 1) * width + ck] + w01 * w11 * v[(ci - 1) * width + ck + 1] + w01 * w10 * v[ci * width + ck + 1];
//
//                // compute the velocity at the center of the cell to get the density
//            }
//        }
//    }
//}

const Simul = struct {
    v: []f32,
    u: []f32,
    width: usize,

    pub fn update(slf: *@This(), dt: f32) void {

        // update velocities
        for (slf.v) |*v| {
            v += -9.81 * dt;
        }

        // compute divergence
        var i: usize = slf.width;
        while (i < slf.v.len - slf.width) : (i += 1) {}
    }
};

pub fn main() !void {
    if (glfw.glfwInit() == 0) {
        std.log.err("Could not initialize GLFW\n", .{});
        return;
    }

    const inotify_instance = inotify.inotify_init1(inotify.IN_NONBLOCK);
    const frag_inotify_id = inotify.inotify_add_watch(inotify_instance, "res/basic.frag", inotify.IN_CLOSE_WRITE);
    var inotify_event: inotify.inotify_event = undefined;

    defer glfw.glfwTerminate();

    // Tell GLFW that we want core profile for opengl
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_CONTEXT_VERSION_MINOR, 3);
    glfw.glfwWindowHint(glfw.GLFW_OPENGL_PROFILE, glfw.GLFW_OPENGL_CORE_PROFILE);

    // Initialize a window
    const window: *glfw.GLFWwindow = if (glfw.glfwCreateWindow(640, 480, "Hello World", null, null)) |w| w else {
        std.log.err("Could not create a GLFW window\n", .{});
        return;
    };

    defer glfw.glfwDestroyWindow(window);

    glfw.glfwMakeContextCurrent(window);

    // vsync
    glfw.glfwSwapInterval(1);

    // data
    const vertices = [_]f32{
        -1.0, -1.0, // 0 (lower left corner)
        1.0, -1.0, // 1 (lower right corner)
        1.0, 1.0, // 2 (upper right corner)
        -1.0, 1.0, // 3 (upper left corner)
    };

    const indices = [_]u32{ 0, 1, 2, 2, 0, 3 };

    gl.blendFunc(.src_alpha, .one_minus_src_alpha);
    gl.enable(.blend);

    const vao = gl.genVertexArray();
    defer gl.deleteVertexArray(vao);

    const ibo = gl.genBuffer();
    const vbo = gl.genBuffer();
    defer gl.deleteBuffers(&[2]gl.Buffer{ vbo, ibo });

    gl.bindBuffer(vbo, .array_buffer);
    gl.bufferData(.array_buffer, f32, &vertices, .static_draw);

    gl.bindVertexArray(vao);
    // push vertex layout: vec2
    gl.enableVertexArrayAttrib(vao, 0);
    gl.vertexAttribPointer(0, 2, .float, false, 2 * @sizeOf(f32), 0);

    // init index buffer
    gl.bindBuffer(ibo, .element_array_buffer);
    gl.bufferData(.element_array_buffer, u32, &indices, .static_draw);

    // load shader
    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    var shader = try buildShader(gpa);

    defer gl.deleteProgram(shader.id);

    var timer = try std.time.Timer.start();

    while (glfw.glfwWindowShouldClose(window) == 0) {

        // poll inotify
        const read = std.os.read(inotify_instance, @ptrCast([*]u8, &inotify_event)[0..@sizeOf(inotify.inotify_event)]) catch 0;
        if (read == @sizeOf(inotify.inotify_event) and inotify_event.wd == frag_inotify_id) {
            std.log.scoped(.watch).info("fragment shader updated", .{});
            shader = if (buildShader(gpa)) |s| b: {
                gl.deleteProgram(shader.id);
                timer.reset(); // reset timer every time we reload shader
                break :b s;
            } else |err| if (err ==
                error.FailedToCompile)
            b: {
                std.log.scoped(.watch).info("keeping last successfully compiled shader", .{});
                break :b shader;
            } else {
                return err;
            };
        }

        // update uniform(s)
        gl.useProgram(shader.id);
        gl.uniform1f(shader.u_time, @intToFloat(f32, timer.read()) * 1e-9);

        // render: clear
        gl.clear(.{ .color = true, .depth = true });
        // render: draw
        gl.useProgram(shader.id);
        gl.bindBuffer(ibo, .element_array_buffer);
        gl.bindBuffer(vbo, .array_buffer);
        gl.drawElements(.triangles, indices.len, .u32, 0);

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
    }
}

const MkShaderError = error{
    FailedToCompile,
};

fn readFile(path: []const u8, alloc: std.mem.Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const file_size = try file.getEndPos();

    const buf = try alloc.alloc(u8, file_size);
    errdefer alloc.free(buf);

    _ = try file.readAll(buf);

    return buf;
}

fn buildShader(alloc: std.mem.Allocator) !Shader {
    const program = try makeShaderProgram("res/basic", alloc);

    return Shader{
        .id = program,
        .u_time = gl.getUniformLocation(program, "u_time"),
    };
}

fn makeShaderProgram(comptime shader_name: []const u8, alloc: std.mem.Allocator) !gl.Program {
    const fs_path = shader_name ++ ".frag";
    const vs_path = shader_name ++ ".vert";

    // read both files
    const fs_source = try readFile(fs_path, alloc);
    defer alloc.free(fs_source);
    const vs_source = try readFile(vs_path, alloc);
    defer alloc.free(vs_source);

    const program = gl.createProgram();
    errdefer gl.deleteProgram(program);

    const fs = try compileShader(.fragment, fs_source, alloc);
    defer gl.deleteShader(fs);

    const vs = try compileShader(.vertex, vs_source, alloc);
    defer gl.deleteShader(vs);

    gl.attachShader(program, fs);
    gl.attachShader(program, vs);

    gl.linkProgram(program);

    return program;
}

fn compileShader(shader_type: gl.ShaderType, source: []const u8, alloc: std.mem.Allocator) !gl.Shader {
    const id = gl.createShader(shader_type);
    gl.shaderSource(id, 1, &[1][]const u8{source});
    gl.compileShader(id);

    const result = gl.getShader(id, .compile_status);
    if (result == 0) {
        const info_log = try gl.getShaderInfoLog(id, alloc);
        defer alloc.free(info_log);
        std.log.scoped(.opengl).err("Failed to compile shader: {s}", .{info_log});
        gl.deleteShader(id);
        return error.FailedToCompile;
    } else {
        return id;
    }
}
