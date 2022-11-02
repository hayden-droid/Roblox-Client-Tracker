#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <SAParams.h>
uniform vec4 CB0[58];
uniform vec4 CB3[1];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform samplerCube PrefilteredEnvIndoorTexture;
uniform samplerCube PrefilteredEnvBlendTargetTexture;
uniform sampler2D PrecomputedBRDFTexture;
uniform sampler2D DiffuseMapTexture;
uniform sampler2D NormalMapTexture;
uniform sampler2D SpecularMapTexture;

in vec2 VARYING0;
in vec4 VARYING2;
in vec4 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
out vec4 _entryPointOutput;

void main()
{
    float f0 = length(VARYING4.xyz);
    vec3 f1 = VARYING4.xyz / vec3(f0);
    vec4 f2 = texture(DiffuseMapTexture, VARYING0);
    float f3 = f2.w;
    vec4 f4 = vec4(mix(VARYING2.xyz, f2.xyz, vec3(f3)), VARYING2.w);
    vec4 f5 = vec4(f2.xyz, VARYING2.w * f3);
    bvec4 f6 = bvec4(!(CB3[0].x == 0.0));
    vec4 f7 = vec4(f6.x ? f4.x : f5.x, f6.y ? f4.y : f5.y, f6.z ? f4.z : f5.z, f6.w ? f4.w : f5.w);
    vec4 f8 = texture(NormalMapTexture, VARYING0);
    vec2 f9 = f8.wy * 2.0;
    vec2 f10 = f9 - vec2(1.0);
    float f11 = sqrt(clamp(1.0 + dot(vec2(1.0) - f9, f10), 0.0, 1.0));
    vec2 f12 = vec3(f10, f11).xy * clamp((vec2(0.0033333334140479564666748046875, CB0[28].y) * (-VARYING4.w)) + vec2(1.0), vec2(0.0), vec2(1.0)).y;
    vec4 f13 = texture(SpecularMapTexture, VARYING0);
    float f14 = gl_FrontFacing ? 1.0 : (-1.0);
    vec3 f15 = VARYING6.xyz * f14;
    vec3 f16 = VARYING5.xyz * f14;
    vec3 f17 = normalize(((f15 * f12.x) + ((cross(f16, f15) * VARYING6.w) * f12.y)) + (f16 * f11));
    vec3 f18 = f7.xyz;
    vec3 f19 = f18 * f18;
    vec4 f20 = f7;
    f20.x = f19.x;
    vec4 f21 = f20;
    f21.y = f19.y;
    vec4 f22 = f21;
    f22.z = f19.z;
    float f23 = CB0[31].w * clamp(1.0 - (VARYING4.w * CB0[28].y), 0.0, 1.0);
    float f24 = 0.08900000154972076416015625 + (f13.y * 0.9110000133514404296875);
    vec3 f25 = -f1;
    vec3 f26 = reflect(f25, f17);
    float f27 = f13.x * f23;
    vec3 f28 = mix(vec3(0.039999999105930328369140625), f22.xyz, vec3(f27));
    vec3 f29 = VARYING7.xyz - (CB0[16].xyz * VARYING3.w);
    float f30 = clamp(dot(step(CB0[24].xyz, abs(VARYING3.xyz - CB0[23].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f31 = VARYING3.yzx - (VARYING3.yzx * f30);
    vec4 f32 = texture(LightMapTexture, f31);
    vec4 f33 = texture(LightGridSkylightTexture, f31);
    vec4 f34 = vec4(clamp(f30, 0.0, 1.0));
    vec4 f35 = mix(f32, vec4(0.0), f34);
    vec4 f36 = mix(f33, vec4(1.0), f34);
    float f37 = f36.x;
    vec4 f38 = texture(ShadowMapTexture, f29.xy);
    float f39 = f29.z;
    vec3 f40 = -CB0[16].xyz;
    float f41 = dot(f17, f40) * ((1.0 - ((step(f38.x, f39) * clamp(CB0[29].z + (CB0[29].w * abs(f39 - 0.5)), 0.0, 1.0)) * f38.y)) * f36.y);
    vec3 f42 = normalize(f1 - CB0[16].xyz);
    float f43 = clamp(f41, 0.0, 1.0);
    float f44 = f24 * f24;
    float f45 = max(0.001000000047497451305389404296875, dot(f17, f42));
    float f46 = dot(f40, f42);
    float f47 = 1.0 - f46;
    float f48 = f47 * f47;
    float f49 = (f48 * f48) * f47;
    vec3 f50 = vec3(f49) + (f28 * (1.0 - f49));
    float f51 = f44 * f44;
    float f52 = (((f45 * f51) - f45) * f45) + 1.0;
    float f53 = 1.0 - f27;
    float f54 = f23 * f53;
    vec3 f55 = vec3(f53);
    float f56 = f24 * 5.0;
    vec3 f57 = vec4(f26, f56).xyz;
    vec3 f58 = textureLod(PrefilteredEnvIndoorTexture, f57, f56).xyz;
    vec3 f59;
    if (CB0[32].w == 0.0)
    {
        f59 = f58;
    }
    else
    {
        f59 = mix(f58, textureLod(PrefilteredEnvBlendTargetTexture, f57, f56).xyz, vec3(CB0[32].w));
    }
    vec4 f60 = texture(PrecomputedBRDFTexture, vec2(f24, max(9.9999997473787516355514526367188e-05, dot(f17, f1))));
    float f61 = f60.x;
    float f62 = f60.y;
    vec3 f63 = ((f28 * f61) + vec3(f62)) / vec3(f61 + f62);
    vec3 f64 = f17 * f17;
    bvec3 f65 = lessThan(f17, vec3(0.0));
    vec3 f66 = vec3(f65.x ? f64.x : vec3(0.0).x, f65.y ? f64.y : vec3(0.0).y, f65.z ? f64.z : vec3(0.0).z);
    vec3 f67 = f64 - f66;
    float f68 = f67.x;
    float f69 = f67.y;
    float f70 = f67.z;
    float f71 = f66.x;
    float f72 = f66.y;
    float f73 = f66.z;
    vec3 f74 = (((((f35.xyz * (f35.w * 120.0)) + ((((f55 - (f50 * f54)) * CB0[15].xyz) * f43) + (CB0[17].xyz * (f53 * clamp(-f41, 0.0, 1.0))))) + (((f55 - (f63 * f54)) * (((((((CB0[40].xyz * f68) + (CB0[42].xyz * f69)) + (CB0[44].xyz * f70)) + (CB0[41].xyz * f71)) + (CB0[43].xyz * f72)) + (CB0[45].xyz * f73)) + (((((((CB0[34].xyz * f68) + (CB0[36].xyz * f69)) + (CB0[38].xyz * f70)) + (CB0[35].xyz * f71)) + (CB0[37].xyz * f72)) + (CB0[39].xyz * f73)) * f37))) * 1.0)) + ((CB0[32].xyz + (CB0[33].xyz * f37)) * 1.0)) * f22.xyz) + ((((f50 * (((f51 + (f51 * f51)) / max(((f52 * f52) * ((f46 * 3.0) + 0.5)) * ((f45 * 0.75) + 0.25), 3.0999999580672010779380798339844e-05)) * f43)) * CB0[15].xyz) * 1.0) + ((mix(f59, textureLod(PrefilteredEnvTexture, f57, f56).xyz * mix(CB0[31].xyz, CB0[30].xyz, vec3(clamp(f26.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f37)) * f63) * f23));
    vec4 f75 = vec4(0.0);
    f75.x = f74.x;
    vec4 f76 = f75;
    f76.y = f74.y;
    vec4 f77 = f76;
    f77.z = f74.z;
    float f78 = f7.w;
    vec4 f79 = f77;
    f79.w = f78;
    float f80 = clamp(exp2((CB0[18].z * f0) + CB0[18].x) - CB0[18].w, 0.0, 1.0);
    vec3 f81 = textureLod(PrefilteredEnvTexture, vec4(f25, 0.0).xyz, max(CB0[18].y, f80) * 5.0).xyz;
    bvec3 f82 = bvec3(!(CB0[18].w == 0.0));
    vec3 f83 = mix(vec3(f82.x ? CB0[19].xyz.x : f81.x, f82.y ? CB0[19].xyz.y : f81.y, f82.z ? CB0[19].xyz.z : f81.z), f79.xyz, vec3(f80));
    vec4 f84 = f79;
    f84.x = f83.x;
    vec4 f85 = f84;
    f85.y = f83.y;
    vec4 f86 = f85;
    f86.z = f83.z;
    vec3 f87 = sqrt(clamp(f86.xyz * CB0[20].y, vec3(0.0), vec3(1.0))) + vec3((-0.00048828125) + (0.0009765625 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))))));
    vec4 f88 = f86;
    f88.x = f87.x;
    vec4 f89 = f88;
    f89.y = f87.y;
    vec4 f90 = f89;
    f90.z = f87.z;
    vec4 f91 = f90;
    f91.w = f78;
    _entryPointOutput = f91;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$PrefilteredEnvIndoorTexture=s14
//$$PrefilteredEnvBlendTargetTexture=s2
//$$PrecomputedBRDFTexture=s11
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$SpecularMapTexture=s5
