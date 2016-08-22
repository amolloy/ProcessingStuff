TreeBranch baseBranch = null;
PImage transformBuffer = null;

color PickColor()
{
  color[] colors = { #BFB7AB,
                     #A89B8E,
                     #EAE9E7,
                     #EAEAEA,
                     #EAE9E7,
                     #EAEAEA,
                     #EAE9E7,
                     #EAEAEA,
                     #EAE9E7,
                     #EAEAEA,
                     #EAE9E7,
                     #EAEAEA,
                     #EAE9E7,
                     #EAEAEA
                   };
  int colorIndex = (int)(random(colors.length));
  colorIndex = min(colors.length - 1, max(0, colorIndex));
  return colors[colorIndex];
}

void setup()
{
  size(1500, 800);
  baseBranch = new TreeBranch(width / 2, 60, 0.0001);
  transformBuffer = createImage(width, height, RGB);
  background(0);
  stroke(PickColor());
}

class TreeBranch
{
  int startX;
  int startWidth;
  int currentWidth;
  ArrayList<PVector> points;
  float horizontalForce;
  PVector growVector;
  
  public TreeBranch(int startX, int startWidth, float startHorizontalForce)
  {
    this.startX = startX;
    this.startWidth = startWidth;
    this.currentWidth = startWidth;
    this.growVector = new PVector(0, -1);
    this.horizontalForce = startHorizontalForce;
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
    strokeWeight(lineWidth);
    
    PVector perp = new PVector(-direction.y, direction.x).normalize();
    
    PVector base = new PVector(point.x, point.y);
    PVector side1 = perp.copy().mult(currentWidth / 2).add(base);
    PVector side2 = perp.copy().mult(-currentWidth / 2).add(base);
    
    
    line(side1.x, side1.y, side2.x, side2.y);
    
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
      if (treeCount > 200)
      {
        println("Done.");
        noLoop();
      }
      else
      {
        loadPixels();
        transformBuffer.pixels = pixels;
        transformBuffer.updatePixels();
        background(0);
        tint(254);
        
        final int pushBack = 5;
        
        image(transformBuffer, pushBack / 2, pushBack / 2, width - pushBack, height - pushBack / 2);
  
        stroke(PickColor());
        
        baseBranch = new TreeBranch((int)(randomGaussian() * width * 0.8 + width * 0.1), 
                                    (int)(randomGaussian() * 50 + 20),
                                    0.0001);
      }
    }
  }
  
  saveFrame();
}