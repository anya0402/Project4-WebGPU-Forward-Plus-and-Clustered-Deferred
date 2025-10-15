// TODO-3: implement the Clustered Deferred fullscreen vertex shader

// This shader should be very simple as it does not need all of the information passed by the the naive vertex shader.


struct VertexOutput
{
    @builtin(position) fragPos: vec4f,
    @location(0) uv: vec2f
}

@vertex
fn main(@builtin(vertex_index) vertexIndex : u32) -> VertexOutput
{
    const corners = array(vec2f(-1.0, -1.0), vec2f(1.0, -1.0), vec2f(-1.0, 1.0), vec2f(-1.0, 1.0), vec2f(1.0, -1.0), vec2f(1.0, 1.0));
    var inPos = corners[vertexIndex];
    var inUV = vec2f((inPos.x * 0.5) + 0.5, 1 - ((inPos.y * 0.5) + 0.5));

    var out: VertexOutput;
    out.fragPos = vec4f(inPos, 0.0, 1.0);
    out.uv = inUV;
    return out;
}
