#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

uniform float r;
uniform float g;
uniform float b;
uniform float a;

uniform vec2 texOffset;
varying vec4 vertColor;
varying vec4 vertTexCoord;

void main() {
  vec4 texColor = texture2D(texture, vertTexCoord.st).rgba;
  //if (texColor.r == 1.0 && texColor.r == texColor.g && texColor.r == texColor.b) {
/*
  if (texColor.r == 0.0 && texColor.r == texColor.g && texColor.r == texColor.b) {
      gl_FragColor = vec4(r, g, b, a);
  } else {
      */
  if (texColor.r == texColor.g && texColor.r == texColor.b) {
      gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
  } else {
      gl_FragColor = vec4(r, g, b, a);
  }
}
