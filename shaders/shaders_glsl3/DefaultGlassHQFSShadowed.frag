#version 150

struct Globals
{
    mat4 ViewProjection;
    vec4 ViewRight;
    vec4 ViewUp;
    vec4 ViewDir;
    vec3 CameraPosition;
    vec3 AmbientColor;
    vec3 SkyAmbient;
    vec3 Lamp0Color;
    vec3 Lamp0Dir;
    vec3 Lamp1Color;
    vec4 FogParams;
    vec4 FogColor_GlobalForceFieldTime;
    vec3 Exposure;
    vec4 LightConfig0;
    vec4 LightConfig1;
    vec4 LightConfig2;
    vec4 LightConfig3;
    vec4 ShadowMatrix0;
    vec4 ShadowMatrix1;
    vec4 ShadowMatrix2;
    vec4 RefractionBias_FadeDistance_GlowFactor_SpecMul;
    vec4 OutlineBrightness_ShadowInfo;
    vec4 SkyGradientTop_EnvDiffuse;
    vec4 SkyGradientBottom_EnvSpec;
    vec3 AmbientColorNoIBL;
    vec3 SkyAmbientNoIBL;
    vec4 AmbientCube[12];
    vec4 CascadeSphere0;
    vec4 CascadeSphere1;
    vec4 CascadeSphere2;
    vec4 CascadeSphere3;
    float hybridLerpDist;
    float hybridLerpSlope;
    float evsmPosExp;
    float evsmNegExp;
    float globalShadow;
    float shadowBias;
    float shadowAlphaRef;
    float debugFlags;
};

struct LightShadowGPUTransform
{
    mat4 transform;
};

struct MaterialParams
{
    float textureTiling;
    float specularScale;
    float glossScale;
    float reflectionScale;
    float normalShadowScale;
    float specularLod;
    float glossLod;
    float normalDetailTiling;
    float normalDetailScale;
    float farTilingDiffuse;
    float farTilingNormal;
    float farTilingSpecular;
    float farDiffuseCutoff;
    float farNormalCutoff;
    float farSpecularCutoff;
    float optBlendColorK;
    float farDiffuseCutoffScale;
    float farNormalCutoffScale;
    float farSpecularCutoffScale;
    float isNonSmoothPlastic;
};

uniform vec4 CB0[47];
uniform vec4 CB8[24];
uniform vec4 CB2[5];
uniform sampler2D ShadowAtlasTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform sampler2D DiffuseMapTexture;
uniform sampler2D NormalMapTexture;
uniform sampler2D NormalDetailMapTexture;
uniform sampler2D StudsMapTexture;
uniform sampler2D SpecularMapTexture;
uniform samplerCube EnvironmentMapTexture;

in vec4 VARYING0;
in vec4 VARYING1;
in vec4 VARYING2;
in vec3 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
in float VARYING8;
out vec4 _entryPointOutput;

void main()
{
    vec2 f0 = VARYING1.xy;
    f0.y = (fract(VARYING1.y) + VARYING8) * 0.25;
    float f1 = clamp(1.0 - (VARYING4.w * CB0[23].y), 0.0, 1.0);
    vec2 f2 = VARYING0.xy * CB2[0].x;
    vec4 f3 = texture(DiffuseMapTexture, f2);
    vec2 f4 = texture(NormalMapTexture, f2).wy * 2.0;
    vec2 f5 = f4 - vec2(1.0);
    float f6 = sqrt(clamp(1.0 + dot(vec2(1.0) - f4, f5), 0.0, 1.0));
    vec2 f7 = (vec3(f5, f6).xy + (vec3((texture(NormalDetailMapTexture, f2 * CB2[1].w).wy * 2.0) - vec2(1.0), 0.0).xy * CB2[2].x)).xy * f1;
    float f8 = f7.x;
    float f9 = f3.w;
    vec3 f10 = ((mix(vec3(1.0), VARYING2.xyz, vec3(clamp(f9 + CB2[3].w, 0.0, 1.0))) * f3.xyz) * (1.0 + (f8 * CB2[1].x))) * (texture(StudsMapTexture, f0).x * 2.0);
    vec4 f11 = mix(texture(SpecularMapTexture, f2 * CB2[2].w), texture(SpecularMapTexture, f2), vec4(clamp((f1 * CB2[4].z) - (CB2[3].z * CB2[4].z), 0.0, 1.0)));
    vec2 f12 = mix(vec2(CB2[1].y, CB2[1].z), (f11.xy * vec2(CB2[0].y, CB2[0].z)) + vec2(0.0, 0.00999999977648258209228515625), vec2(f1));
    float f13 = VARYING2.w * 2.0;
    float f14 = clamp(f13, 0.0, 1.0);
    float f15 = clamp((f13 - 1.0) + f9, 0.0, 1.0);
    vec3 f16 = normalize(((VARYING6.xyz * f8) + (cross(VARYING5.xyz, VARYING6.xyz) * f7.y)) + (VARYING5.xyz * (f6 * 10.0)));
    vec3 f17 = -CB0[11].xyz;
    float f18 = dot(f16, f17);
    float f19 = clamp(dot(step(CB0[19].xyz, abs(VARYING3 - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f20 = VARYING3.yzx - (VARYING3.yzx * f19);
    vec4 f21 = vec4(clamp(f19, 0.0, 1.0));
    vec4 f22 = mix(texture(LightMapTexture, f20), vec4(0.0), f21);
    vec4 f23 = mix(texture(LightGridSkylightTexture, f20), vec4(1.0), f21);
    vec3 f24 = (f22.xyz * (f22.w * 120.0)).xyz;
    float f25 = f23.x;
    float f26 = f23.y;
    vec3 f27 = VARYING7.xyz - CB0[41].xyz;
    vec3 f28 = VARYING7.xyz - CB0[42].xyz;
    vec3 f29 = VARYING7.xyz - CB0[43].xyz;
    vec4 f30 = vec4(VARYING7.xyz, 1.0) * mat4(CB8[((dot(f27, f27) < CB0[41].w) ? 0 : ((dot(f28, f28) < CB0[42].w) ? 1 : ((dot(f29, f29) < CB0[43].w) ? 2 : 3))) * 4 + 0], CB8[((dot(f27, f27) < CB0[41].w) ? 0 : ((dot(f28, f28) < CB0[42].w) ? 1 : ((dot(f29, f29) < CB0[43].w) ? 2 : 3))) * 4 + 1], CB8[((dot(f27, f27) < CB0[41].w) ? 0 : ((dot(f28, f28) < CB0[42].w) ? 1 : ((dot(f29, f29) < CB0[43].w) ? 2 : 3))) * 4 + 2], CB8[((dot(f27, f27) < CB0[41].w) ? 0 : ((dot(f28, f28) < CB0[42].w) ? 1 : ((dot(f29, f29) < CB0[43].w) ? 2 : 3))) * 4 + 3]);
    vec4 f31 = textureLod(ShadowAtlasTexture, f30.xy, 0.0);
    vec2 f32 = vec2(0.0);
    f32.x = CB0[45].z;
    vec2 f33 = f32;
    f33.y = CB0[45].w;
    float f34 = (2.0 * f30.z) - 1.0;
    float f35 = exp(CB0[45].z * f34);
    float f36 = -exp((-CB0[45].w) * f34);
    vec2 f37 = (f33 * CB0[46].y) * vec2(f35, f36);
    vec2 f38 = f37 * f37;
    float f39 = f31.x;
    float f40 = max(f31.y - (f39 * f39), f38.x);
    float f41 = f35 - f39;
    float f42 = f31.z;
    float f43 = max(f31.w - (f42 * f42), f38.y);
    float f44 = f36 - f42;
    float f45 = (f18 > 0.0) ? mix(f26, mix(min((f35 <= f39) ? 1.0 : clamp(((f40 / (f40 + (f41 * f41))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0), (f36 <= f42) ? 1.0 : clamp(((f43 / (f43 + (f44 * f44))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0)), f26, clamp((length(VARYING7.xyz - CB0[7].xyz) * CB0[45].y) - (CB0[45].x * CB0[45].y), 0.0, 1.0)), CB0[46].x) : 0.0;
    vec3 f46 = f10 * f10;
    vec3 f47 = normalize(VARYING4.xyz);
    vec3 f48 = texture(EnvironmentMapTexture, reflect(-VARYING4.xyz, f16)).xyz;
    vec3 f49 = mix(f24, (f48 * f48) * CB0[15].x, vec3(f25)) * mix(vec3(1.0), f46, vec3(0.5));
    float f50 = 1.0 - dot(f16, f47);
    vec4 f51 = mix(vec4(mix((min(f24 + (CB0[8].xyz + (CB0[9].xyz * f25)), vec3(CB0[16].w)) + (((CB0[10].xyz * clamp(f18, 0.0, 1.0)) + (CB0[12].xyz * max(-f18, 0.0))) * f45)) * f46, f49, vec3(mix((f11.y * f1) * CB2[0].w, 1.0, VARYING7.w))) * f15, f15), vec4(f49, 1.0), vec4(((f50 * f50) * 0.800000011920928955078125) * f14)) + vec4(CB0[10].xyz * ((((step(0.0, f18) * mix(f12.x, CB2[0].y, VARYING7.w)) * f45) * pow(clamp(dot(f16, normalize(f17 + f47)), 0.0, 1.0), mix(f12.y, CB2[0].z, VARYING7.w))) * f14), 0.0);
    float f52 = clamp((CB0[13].x * length(VARYING4.xyz)) + CB0[13].y, 0.0, 1.0);
    vec3 f53 = mix(CB0[14].xyz, sqrt(clamp(f51.xyz * CB0[15].y, vec3(0.0), vec3(1.0))).xyz, vec3(f52));
    vec4 f54 = vec4(f53.x, f53.y, f53.z, f51.w);
    f54.w = mix(1.0, f51.w, f52);
    _entryPointOutput = f54;
}

//$$ShadowAtlasTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$NormalDetailMapTexture=s8
//$$StudsMapTexture=s0
//$$SpecularMapTexture=s5
//$$EnvironmentMapTexture=s2
