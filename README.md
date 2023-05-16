# Unity Planar Shadows

## Results

![image](GithubContent/preview.png)

*Note: In the preview, you can see the planar shadows in action. Blob shadows are also used in conjunction to give the impression of AO. Together they can create very convincing lighting for cheap!*

## How It Works

Planar Shadow is an old school technique for cheap shadowing *(Which makes it very useful for mobile games)* Unity’s default shadowing system uses Shadowmaps, however these utilize Pixel Shaders and Render Targets. That means that Shadowmap system is expensive especially on mobile devices. (This also applies to other engines, not just for Unity).

Planar Shadows are not real shadows. It is just a mesh. But, it looks like a shadow by pressing/projecting into plane using the Vertex Shader. It doesn’t need much power of Pixel Shader.

It uses a little bit of math, but, simple trigonometric function. See image below : P is a point of the mesh and P' is a point of the shadow. 

![image](GithubContent/alittlebitmath.jpg)

```
float4 vPosWorld = mul( _Object2World, v.vertex);
float4 lightDirection = -normalize(_WorldSpaceLightPos0); 
float opposite = vPosWorld.y - _PlaneHeight;
float cosTheta = -lightDirection.y;	// = lightDirection dot (0,-1,0)
float hypotenuse = opposite / cosTheta;
float3 vPos = vPosWorld.xyz + ( lightDirection * hypotenuse );
o.pos = mul (UNITY_MATRIX_VP, float4(vPos.x, _PlaneHeight, vPos.z ,1));  
```

Detailed explain(Korean) : http://ozlael.tistory.com/10

### Advantages
1. Cheap! Core part is only for the Vertex Shader. The Pixel Shader handles only color and alpha (plus, Stencil)
2. You can use LOD mesh for shadows. While shadowmaps *(Unity’s shadows)* have to draw original mesh at least twice.
3. Shadows are pixel perfect compared to shadowmaps. Mobile devices have to use blocky hard shadow because they doesn't have enough power to use soft shadows.
4. ***NEW:*** Works with baked lighting. Using light probes, it computes the dominant direction of light.

### Disadvantages
1. **Only works on planar/flat surfaces** *(Does not work on sloped or complex surfaces)*.
2. Only hard shadows.
3. Uses Stencil. But, It is not a big deal nowadays because mobile devices are support it.
4. The shadow will slide around with the baked lighting approach as new dominant sources of light change.

### Future Plans
- Add support for additional lights beyond just the directional light (i.e. spot/point lights).
- Fix layering issue with other duplicate shadow meshes that are casting shadows from realtime lights rather than baked lights.

## Credits

This is based off the work done by **[ozlael](https://github.com/ozlael)** on his [original project](https://github.com/ozlael/PlannarShadowForUnity) so all credit goes to him for the main clever implementation!

As for my contributions... 

I've cleaned up and refactored the code for simplicity and clarity, and also so it's all contained in one simple shader. I've added [Single-Pass Instancing](https://docs.unity3d.com/Manual/SinglePassInstancing.html) VR support. I've also added support to work with 100% baked lighting, by sampling the dominant direction of light from light probes. Lastly I've introduced a user adjustable value that roughly controls the length of the shadow *(so when the light direction is coming from oblique or grazing angles, you can limit the length of the shadows).*
