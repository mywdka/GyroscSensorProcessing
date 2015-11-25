#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;
uniform vec2 texOffset;

varying vec4 vertColor;
varying vec4 vertTexCoord;


void main()
{
   vec4 sum = vec4(0);
   int j;
   int i;
   float col;

    for( i= -4 ;i < 4; i++)
    {
        for (j = -3; j < 3; j++)
        {
            sum += texture2D(texture, vertTexCoord.st + vec2(j, i)*0.004) * 0.25;
        }
    }

    col = (texture2D(texture, vertTexCoord.st).r +
           texture2D(texture, vertTexCoord.st).g +
           texture2D(texture, vertTexCoord.st).b) / 3.0;

    if (col < 0.3)
    {
       gl_FragColor = sum*sum*0.012 + texture2D(texture, vertTexCoord.st);
    }
    else
    {
        if (col < 0.5)
        {
            gl_FragColor = sum*sum*0.009 + texture2D(texture, vertTexCoord.st);
        }
        else
        {
            gl_FragColor = sum*sum*0.0075 + texture2D(texture, vertTexCoord.st);
        }
    }
}
