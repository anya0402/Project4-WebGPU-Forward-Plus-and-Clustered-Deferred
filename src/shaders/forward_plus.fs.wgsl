// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights

// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).

@group(${bindGroup_scene}) @binding(0) var<uniform> cameraUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;

@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }

    let fragView = cameraUniforms.viewProjMat * vec4f(in.pos, 1.0);
    let fragDevice = fragView.xy / fragView.w;
    let fragScreen = (fragDevice * 0.5) + vec2f(0.5, 0.5);

    let toViewSpace = cameraUniforms.viewMat * vec4f(in.pos, 1.0);

    // let zDepth = (log(abs(toViewSpace.z) / camera.nearPlane) * clusterSet.numClusters[2]) / log(camera.farPlane / camera.nearPlane);
    let numClustersZFloat = f32(clusterSet.numClusters[2]);
    let zDepth = (log(abs(toViewSpace.z) / ${nearPlane}) * numClustersZFloat) / log(${farPlane} / ${nearPlane});

    let clusterX = u32(clamp(fragScreen.x * f32(clusterSet.numClusters[0]), 0.0, f32(clusterSet.numClusters[0] - 1)));
    let clusterY = u32(clamp(fragScreen.y * f32(clusterSet.numClusters[1]), 0.0, f32(clusterSet.numClusters[1] - 1)));
    let clusterZ = u32(clamp(zDepth * f32(clusterSet.numClusters[2]), 0.0, f32(clusterSet.numClusters[2] - 1)));

    let clusterIdx = clusterX + clusterY * clusterSet.numClusters[0] + clusterZ * clusterSet.numClusters[0] * clusterSet.numClusters[1];
    // let currCluster = clusterSet.clusters[clusterIdx];

    var totalLightContrib = vec3f(0, 0, 0);
    for (var lightIdx = 0u; lightIdx < clusterSet.clusters[clusterIdx].numLights; lightIdx++) {
        let light = lightSet.lights[clusterSet.clusters[clusterIdx].light_indices[lightIdx]];
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
    }

    var finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
