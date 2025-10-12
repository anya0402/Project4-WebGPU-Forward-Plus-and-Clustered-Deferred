// TODO-2: implement the light clustering compute shader

// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.

//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.

//     - Store the number of lights assigned to this cluster.

@group(${bindGroup_scene}) @binding(0) var<uniform> cameraUniforms: CameraUniforms;
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read_write> clusterSet: ClusterSet;

@compute
@workgroup_size(${clusterWorkgroupSize})
fn main(@builtin(global_invocation_id) index: vec3u) { 
    let clusterIndex = index.x + index.y * clusterSet.numClusters[0] + index.z * clusterSet.numClusters[0] * clusterSet.numClusters[1];
    // let currCluster = clusterSet.clusters[clusterIndex];

    // xy screen space
    let xScreen = 2.0 / f32(clusterSet.numClusters[0]);
    let yScreen = 2.0 / f32(clusterSet.numClusters[1]);
    let xMin = -1.0 + (f32(index.x) * xScreen); //offset
    let yMin = -1.0 + (f32(index.y) * yScreen);
    let xMax = xMin + xScreen;
    let yMax = yMin + yScreen;

    // z depth bounds - log slice
    let zNear = ${nearPlane} * pow(${farPlane} / ${nearPlane}, f32(index.z) / f32(clusterSet.numClusters[2]));
    let zFar = ${nearPlane} * pow(${farPlane} / ${nearPlane}, f32(index.z + 1u) / f32(clusterSet.numClusters[2]));

    let screenMinPt = vec4f(xMin, yMin, -1.0, 1.0);
    let screenMaxPt = vec4f(xMax, yMax, -1.0, 1.0);
    let invView = cameraUniforms.invViewProjMat;
    let viewMinPt = invView * screenMinPt;
    let viewMaxPt = invView * screenMaxPt;
    let newViewMinPt = viewMinPt / viewMinPt.w;
    let newViewMaxPt = viewMaxPt / viewMaxPt.w;

    let finalMinPt = normalize(newViewMinPt.xyz) * zNear;
    let finalMaxPt = normalize(newViewMaxPt.xyz) * zFar;

    let aabbMin = min(finalMinPt, finalMaxPt);
    let aabbMax = max(finalMinPt, finalMaxPt);;

    clusterSet.clusters[clusterIndex].aabbMin = aabbMin;
    clusterSet.clusters[clusterIndex].aabbMax = aabbMax;

    // assign lights
    let numLights = lightSet.numLights;
    var lightCount: u32 = 0;
    for (var i: u32 = 0u; i < numLights; i++) {
        if (lightCount < ${maxLightsPerCluster}) {
            let currLight = lightSet.lights[i];
            let pointNearBox = clamp(currLight.pos, aabbMin, aabbMax);
            let distToPoint = length(pointNearBox - currLight.pos);
            let isIntersected = distToPoint < ${lightRadius};
            if (isIntersected) {
                clusterSet.clusters[clusterIndex].light_indices[lightCount] = i;
                lightCount++;
            }
        }
    }
    clusterSet.clusters[clusterIndex].numLights = lightCount;

}
