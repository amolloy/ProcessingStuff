final int tintAmount = 254;
final color backgroundColor = #C6D3D2;
final int pushBack = 5;
PVector eye = null;

TreeBranch baseBranch = null;
PImage transformBuffer = null;

color PickColor()
{
  color[] colors = { #BFB7AB,
                     #A89B8E,
                     #EAE9E7,
                     #EAEAEA,
                   };
  int colorIndex = (int)(random(colors.length));
  colorIndex = min(colors.length - 1, max(0, colorIndex));
  color c = colors[colorIndex];
  return color(red(c), green(c), blue(c), 0xAA);
}

void setup()
{
  size(1500, 800, P3D);
  perspective();
  baseBranch = new TreeBranch(width / 2, 60, 0.0001, -1);
  transformBuffer = createImage(width, height, RGB);
  background(backgroundColor);
  fill(PickColor());
  noStroke();
  eye = new PVector(width / 2.0, height / 2.0,  (height/2.0) / tan(PI*30.0 / 180.0));
}

class TreeBranch
{
  int startX;
  int startWidth;
  int currentWidth;
  ArrayList<PVector> points;
  float horizontalForce;
  PVector growVector;
  float depth;
  
  public TreeBranch(int startX, int startWidth, float startHorizontalForce, float depth)
  {
    this.startX = startX;
    this.startWidth = startWidth;
    this.currentWidth = startWidth;
    this.growVector = new PVector(0, -1);
    this.horizontalForce = startHorizontalForce;
    this.depth = depth;
  }
  
  PVector lastPoint()
  {
    PVector lastPoint = null;
    if (points != null)
    {
      lastPoint = points.get(points.size() - 1);
    }
    
    return lastPoint;
  }
  
  void step()
  {
    PVector point = null;
    PVector lastPoint = lastPoint();
    if (points == null)
    {
      points = new ArrayList();
      point = new PVector(startX, height);
    }
    else
    {
      point = lastPoint().copy().add(growVector);
    }
   
    points.add(point);
    if (lastPoint == null)
    {
      lastPoint = new PVector(point.x, point.y + 1);
    }
    
    PVector direction = point.copy().sub(lastPoint);
    float magnitude = direction.mag();
    
    float lineWidth = magnitude * 0.5;
    lineWidth = min(5, max(1, lineWidth));
    
    PVector perp = new PVector(-direction.y, direction.x).normalize();
    
    PVector base = new PVector(point.x, point.y);
    PVector side1 = perp.copy().mult(currentWidth / 2).add(base);
    PVector side2 = perp.copy().mult(-currentWidth / 2).add(base);
    side1.z = depth;
    side2.z = depth;
    
    for (int i = 0; i < 3; ++i)
    {
      PVector jitteredEye = eye.copy();
      jitteredEye.x+= random(-5, 5);
      jitteredEye.y+= random(-5, 5);
      camera(jitteredEye.x, jitteredEye.y, jitteredEye.z, width/2.0, height/2.0, 0, 0, 1, 0);
      litLine(side1, side2, lineWidth, new PVector(0,0,1));
    } 
    
    growVector.x+= horizontalForce;
    
    float adjust = -growVector.x * random(50) / 50;
    horizontalForce+= adjust;
  }
  
  Boolean done()
  {
    Boolean done = false;

    if (points != null)
    {
      int count = points.size();
      if (count > 50)
      {
        int outsideBoundsCount = 0;
        for (int i = 1; i <= count; ++i)
        {
          PVector point = points.get(points.size() - i);
          if (point.x < -50 || point.x > (width + 50) ||
              point.y < -50 || point.y > (height + 50))
          {
            outsideBoundsCount+= 1;
          }
        }
      
        if (outsideBoundsCount > 40)
        {
          done = true;
        }
      }
    }
    
    return done;
  }
}

int treeCount = 0;

void litLine(PVector v0, PVector v1, float lineWidth, PVector viewVector)
{
  PVector offset = v1.copy().sub(v0);
  offset.normalize();
          
  PVector right = offset.copy().cross(viewVector);
  right.normalize();
  right.mult(lineWidth);
          
  PVector nrm = viewVector.copy().mult(-1);
          
  beginShape( QUADS );

  normal   ( nrm.x,           nrm.y,           nrm.z          );
  vertex   ( v1.x,            v1.y,            v1.z           );
    
  normal   ( nrm.x,           nrm.y,           nrm.z          );
  vertex   ( v0.x,            v0.y,            v0.z           );
    
  normal   ( nrm.x,           nrm.y,           nrm.z          );
  vertex   ( v0.x + right.x,  v0.y + right.y,  v0.z + right.z );
    
  normal   ( nrm.x,           nrm.y,           nrm.z          );
  vertex   ( v1.x + right.x,  v1.y + right.y,  v1.z + right.z );

  endShape();
}
void draw()
{
  lightFalloff(1.0, 0.001, 0.0);
  ambientLight(255,255,255);
  
  for (int i = 0; i < 20; ++i)
  {
    baseBranch.step();
    
    if (baseBranch.done())
    {
      treeCount+= 1;
      if (treeCount > 100)
      {
        println("Done.");
        noLoop();
      }
      else
      {
        /*
        loadPixels();
        transformBuffer.pixels = pixels;
        transformBuffer.updatePixels();
        background(backgroundColor);
        if (tintAmount >= 0)
        {
          tint(tintAmount);
        }
        
        image(transformBuffer, pushBack / 2, pushBack / 2, width - pushBack, height - pushBack / 2);
        */
        
        fill(PickColor());
        
        float oldDepth = baseBranch.depth;
        baseBranch = new TreeBranch((int)(randomGaussian() * width * 0.8 + width * 0.1), 
                                    (int)(randomGaussian() * 50 + 20),
                                    0.0001,
                                    oldDepth + random(0.3));
      }
    }
  }
  
  saveFrame();
}