#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

uniform vec4 innerColor;
uniform vec4 outerColor;
uniform float radius;

varying vec4 vertTexCoord;

void main()
{
	vec2 pt = (vertTexCoord.xy - 0.5) * (radius * 2);
    float t = sqrt(pt.x * pt.x + pt.y * pt.y);
    float ft = t / radius;
    
	if (ft > 1)
	{
		gl_FragColor = vec4(0);
	}
	else
	{
		gl_FragColor = mix(innerColor, outerColor, t / radius);
	}
}