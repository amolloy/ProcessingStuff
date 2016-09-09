final color colors[] = 
{
#FF15A9,
#D51059,
#FD4327,
#E52717,
#811A15,
#431A13,
#3D0D56,
#3D0D56,
#0D175F,
#005E80,
#0091C1,
#0B3518,
#00570E,
#007314,
#00B000,
#75C300,
#FCE300,
#FFB000
};

void setup()
{
 size(1000, 1000, P3D);
 background(150);
 stroke(0, 50);
 float xstart = random(10);
 float ynoise = random(10);
 translate(width / 2, height / 2, 0);
 
 for(float y = -(height / 8); y <= (height / 8); y+= 3)
 {
   fill(colors[int(random(colors.length))], 200);

   ynoise += 0.02;
  float xnoise = xstart;
  for(float x = -(width / 8); x <= (width / 8); x += 3)
  {
   xnoise += 0.02;
   

   
   drawPoint(x, y, noise(xnoise, ynoise));
  }
 }
 
 saveFrame();
}

void drawPoint(float x, float y, float noiseFactor)
{
 pushMatrix();
 translate(x * noiseFactor * 5, y * noiseFactor * 4, -y);
 float edgeSize = noiseFactor * 26;
 ellipse(0, 0, edgeSize, edgeSize);
 popMatrix();
}