#version 150

#extension GL_ARB_shading_language_include : require
#include <Params.h>
uniform vec4 CB1[10];
uniform sampler2D iChannel0Texture;

in vec2 VARYING0;
out float _entryPointOutput;

void main()
{
    vec2 f0 = CB1[0].zw * (2.0 * CB1[1].x);
    vec2 f1 = CB1[0].zw * CB1[1].x;
    _entryPointOutput = max((((texture(iChannel0Texture, VARYING0 + f0).x + texture(iChannel0Texture, VARYING0 + f1).x) + texture(iChannel0Texture, VARYING0 - f1).x) + texture(iChannel0Texture, VARYING0 - f0).x) * 0.25, texture(iChannel0Texture, VARYING0).x);
}

//$$iChannel0Texture=s0
