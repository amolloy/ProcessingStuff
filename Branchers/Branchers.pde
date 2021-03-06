import java.lang.Math.*;
import java.util.ArrayList;

final int margin = 10;

class Point
{
  public int x, y;
  public Point(int x, int y)
  {
    this.x = x;
    this.y = y;
  }
}

class Agent
{
  double direction; // Angle in degrees
  double speed; // In pixels per frame
  Point location;
  Point lastBranch;
  double branchDistance;
  
  public Agent(double direction, double speed, Point startingLocation, double branchDistance)
  {
    this.direction = direction;
    this.speed = speed;
    this.location = startingLocation;
    this.lastBranch = startingLocation;
    this.branchDistance = branchDistance;
  }
  
  Boolean checkedLine(int x0, int y0, int x1, int y1)
  {
    int d = 0;
 
    int dy = Math.abs(y1 - y0);
    int dx = Math.abs(x1 - x0);
 
    int dy2 = (dy << 1); // slope scaling factors to avoid floating
    int dx2 = (dx << 1); // point
 
    int ix = x0 < x1 ? 1 : -1;
    int iy = y0 < y1 ? 1 : -1;
 
    int inX = x0;
    int inY = y0;
 
    if (dy <= dx) 
    {
      for (;;)
      {
        if (x0 != inX && get(x0, y0) == 0xFF000000)
        {
          return true;
        }
        point(x0, y0);
        if (x0 == x1)
        {
          break;
        }
        x0 += ix;
        d += dy2;
        if (d > dx) 
        {
          y0 += iy;
          d -= dx2;
        }
      }
    }
    else
    {
      for (;;) 
      {
        if (inY != y0 && get(x0, y0) == 0xFF000000)
        {
          return true;
        }
        point(x0, y0);
        
        if (y0 == y1)
        {
          break;
        }
        y0 += iy;
        d += dx2;
        if (d > dy)
        {
          x0 += ix;
          d -= dy2;
        }
      }
    }
    
    return false;
}

  
  public ArrayList<Agent> step()
  {
    ArrayList<Agent> nextStepAgents = new ArrayList<Agent>();
    
    double velx = Math.cos(Math.toRadians(direction)) * speed;
    double vely = Math.sin(Math.toRadians(direction)) * speed;
    Point newLocation = new Point((int)(location.x + velx),
                                  (int)(location.y + vely));
    Point oldLocation = location;
    
    if ((Math.abs(lastBranch.x - newLocation.x) >= branchDistance) ||
        (Math.abs(lastBranch.y - newLocation.y) >= branchDistance))
    {
      lastBranch = newLocation;
      double branchAngle = random(170) - 85;
      Agent newAgent = new Agent(direction + branchAngle, speed, newLocation, branchDistance);
      nextStepAgents.add(newAgent);
    }

    location = newLocation;

    Boolean intersected = checkedLine(oldLocation.x, oldLocation.y, newLocation.x, newLocation.y);

    Point offset = new Point(location.x - width / 2,
                             location.y - height / 2);
    double distFromCenter = sqrt((offset.x * offset.x) + (offset.y * offset.y));

    if (distFromCenter <= (width / 2 - margin * 2))
    {
      if (intersected)
      {
        println(" not intersected");
      }
      else
      {
        nextStepAgents.add(this);
      }
    }

    return nextStepAgents;
  }
}

ArrayList<Agent> agents = new ArrayList<Agent>();

void setup()
{
  size(800, 800);
  noSmooth();
  
  double speed = 5;
  double branchDist = 15;
  
  int startCount = (int)random(10);
  for (int i = 0; i < startCount; ++i)
  {
    Agent agent = new Agent(random(359), speed, new Point(width / 2, height / 2), branchDist);
    agents.add(agent);
  }
}

void draw()
{
  ArrayList<Agent> nextStepAgents = new ArrayList<Agent>();
  for (Agent agent : agents)
  {
    nextStepAgents.addAll(agent.step());
  }
  agents = nextStepAgents;
  
  if (agents.size() == 0)
  {
    noLoop();
  }
  
  saveFrame();
}