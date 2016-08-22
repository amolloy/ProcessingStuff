TreeBranch baseBranch = null;

void setup()
{
  size(800, 800);
  baseBranch = new TreeBranch(width / 2, 40, 0.0001);
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
      int count = min(50, points.size());
      
      int outsideBoundsCount = 0;
      for (int i = 1; i <= count; ++i)
      {
        PVector point = points.get(points.size() - i);
        if (point.x < 0 || point.x > width ||
            point.y < 0 || point.y > height)
        {
          outsideBoundsCount+= 1;
        }
      }
      
      if (outsideBoundsCount > 8)
      {
        done = true;
      }
    }
    
    return done;
  }
}

void draw()
{
  for (int i = 0; i < 5; ++i)
  {
    baseBranch.step();
    
    if (baseBranch.done())
    {
      println("Done");
      noLoop();
    }
  }
}