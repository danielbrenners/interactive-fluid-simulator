
attribute vec4 position;   //2D position of the vertex. Already position properly in OpenGL coordinates by our program, but often will correspond to the actual location in a 3D model, and transforms will be applied each frame based on other inputs.

attribute float density;  //density of the fluid at this vertex

uniform mat4 modelViewProjectionMatrix;
uniform lowp vec4 fluidColor;   //base color of the fluid  RGBA

varying lowp vec4 colorVarying;    //varyings are sort of like the outputs of vertex shaders. They're values that are assignable, and that carry over to fragment shaders if you declare one over there with the same name, type, etc.

void main()
{
    //some crap, this stuff keeps changing.
    float densRatio = density/(0.4);
//    if(densRatio>1.0) {
//        densRatio = 1.0;
//    }
    
    //the point is that at the end, colorVarying is assigned to be sent to our fragment shader
    colorVarying = fluidColor*densRatio;
    vec4 newPosition = vec4(position[0], position[1], 0.0, 1.0);
    
    //and gl_Position is assigned. It is REQUIRED that a valid vec4 be assigned to this variable before the end of every vertex shader (or it might be at least one of gl_Position and a couple other variables, but this is the most straightforward one). Your program will break and OpenGL will throw a fit if you don't assign something to gl_Position (ibid).
    gl_Position = newPosition * modelViewProjectionMatrix;
}
