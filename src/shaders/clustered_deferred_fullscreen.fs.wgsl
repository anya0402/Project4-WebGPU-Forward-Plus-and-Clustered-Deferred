// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.

@group(${bindGroup_scene}) @binding(0) var<uniform> cameraUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_model}) @binding(0) var positionTex: texture_2d<f32>;
@group(${bindGroup_model}) @binding(1) var normalTex: texture_2d<f32>;
@group(${bindGroup_model}) @binding(2) var albedoTex: texture_2d<f32>;
@group(${bindGroup_model}) @binding(3) var gBuffTexSampler: sampler;

struct FragmentInput
{
    @builtin(position) fragPos: vec4f,
    @location(0) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let posTex = textureSample(positionTex, gBuffTexSampler, in.uv).xyz;
    let normalTex = textureSample(normalTex, gBuffTexSampler, in.uv).xyz;
    let albedoTex = textureSample(albedoTex, gBuffTexSampler, in.uv);
    if (albedoTex.a < 0.5f) {
        discard;
    }

    let fragView = cameraUniforms.viewProjMat * vec4f(posTex, 1.0);
    let fragDevice = fragView.xy / fragView.w;
    let fragScreen = (fragDevice * 0.5) + vec2f(0.5, 0.5);

    let toViewSpace = cameraUniforms.viewMat * vec4f(posTex, 1.0);

    let numClustersZFloat = f32(clusterSet.numClusters[2]);
    let zDepth = (log(abs(toViewSpace.z) / ${nearPlane}) * numClustersZFloat) / log(${farPlane} / ${nearPlane});

    let clusterX = u32(clamp(fragScreen.x * f32(clusterSet.numClusters[0]), 0.0, f32(clusterSet.numClusters[0] - 1)));
    let clusterY = u32(clamp(fragScreen.y * f32(clusterSet.numClusters[1]), 0.0, f32(clusterSet.numClusters[1] - 1)));
    let clusterZ = u32(clamp(zDepth * f32(clusterSet.numClusters[2]), 0.0, f32(clusterSet.numClusters[2] - 1)));

    let clusterIdx = clusterX + clusterY * clusterSet.numClusters[0] + clusterZ * clusterSet.numClusters[0] * clusterSet.numClusters[1];

    var totalLightContrib = vec3f(0, 0, 0);
    for (var lightIdx = 0u; lightIdx < clusterSet.clusters[clusterIdx].numLights; lightIdx++) {
        let light = lightSet.lights[clusterSet.clusters[clusterIdx].light_indices[lightIdx]];
        totalLightContrib += calculateLightContrib(light, posTex, normalTex);
    }

    var finalColor = albedoTex.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
