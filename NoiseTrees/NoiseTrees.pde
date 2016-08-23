final color backgroundColor = #C6D3D2;
final int iterations = 150;
PVector eye = null;

TreeBranch baseBranch = null;
PImage transformBuffer = null;

color PickColor()
{
  color[] colors = { #BFB7AB,
                     #A89B8E,
                     #EAE9E7,
                     #EAEAEA,
                     #D09C70,
                     #B08375,
                     #AB8A59
                   };
  int colorIndex = (int)(random(colors.length));
  colorIndex = min(colors.length - 1, max(0, colorIndex));
  return colors[colorIndex];
}

void setup()
{
  size(1500, 800, P3D);
  perspective();
  baseBranch = new TreeBranch(width / 2, 60, 0.0001, -1, PickColor());
  transformBuffer = createImage(width, height, RGB);
  background(backgroundColor);
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
  color theColor;
  
  public TreeBranch(int startX, int startWidth, float startHorizontalForce, float depth, color theColor)
  {
    this.startX = startX;
    this.startWidth = startWidth;
    this.currentWidth = startWidth;
    this.growVector = new PVector(0, -1);
    this.horizontalForce = startHorizontalForce;
    this.depth = depth;
    this.theColor = theColor;
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
    
    float jitterAmount = max(0, (20.0 - depth) / 20.0);
    color baseColor = lerpColor(theColor, backgroundColor, jitterAmount * jitterAmount);

    stroke(color(red(baseColor), green(baseColor), blue(baseColor), 0xF0));
    camera();
    strokeWeight(lineWidth);
    line(side1.x, side1.y, side1.z, side2.x, side2.y, side2.z);

    stroke(color(red(baseColor), green(baseColor), blue(baseColor), 0xFF / 10));

    jitterAmount*= 6;
    for (int i = 0; i < 10; ++i)
    {
      PVector jitteredEye = eye.copy();
      jitteredEye.x+= random(-jitterAmount, jitterAmount);
      jitteredEye.y+= random(-jitterAmount, jitterAmount);
      camera(jitteredEye.x, jitteredEye.y, jitteredEye.z, width/2.0, height/2.0, 0, 0, 1, 0);
      line(side1.x, side1.y, side1.z, side2.x, side2.y, side2.z);
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

void draw()
{
  for (int i = 0; i < 20; ++i)
  {
    baseBranch.step();
    
    if (baseBranch.done())
    {
      treeCount+= 1;
      if (treeCount > iterations)
      {
        println("Done.");
        save("trees.jpg");
        noLoop();
      }
      else
      {
        float oldDepth = baseBranch.depth;
        baseBranch = new TreeBranch((int)(randomGaussian() * width * 0.8 + width * 0.1), 
                                    (int)(randomGaussian() * 40 + 20),
                                    0.0001,
                                    oldDepth + random(0.3),
                                    PickColor());
      }
    }
  }
}