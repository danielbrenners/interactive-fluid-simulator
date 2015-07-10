

varying lowp vec4 colorVarying;

void main()
{
    //similar to gl_Position in the vertex shader, you MUST assign a valid vec4 to gl_FragColor before the end of your fragment shader
    gl_FragColor = colorVarying;
}