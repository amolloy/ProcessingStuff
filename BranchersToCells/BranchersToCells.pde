import java.lang.Math.*;
import java.util.ArrayList;

final int margin = 40;
final int branchAngleMinRange = -30;
final int branchAngleMaxRange = 30;
final int minStartingAgents = 5;
final int maxStartingAgents = 10;
final double speed = 10;
final double branchDist = 10;
final double maxCellSize = 30;

ArrayList<PVector> intersectionPoints = new ArrayList<PVector>();

class Agent
{
  double direction; // Angle in degrees
  double speed; // In pixels per frame
  PVector location;
  PVector lastBranch;
  double branchDistance;
  
  public Agent(double direction, double speed, PVector startingLocation, double branchDistance)
  {
    this.direction = direction;
    this.speed = speed;
    this.location = startingLocation;
    this.lastBranch = startingLocation;
    this.branchDistance = branchDistance;
  }
  
  Boolean checkedLine(PVector pt1, PVector pt2)
  {
    int x0 = (int)pt1.x;
    int x1 = (int)pt2.x;
    int y0 = (int)pt1.y;
    int y1 = (int)pt2.y;
    
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
          intersectionPoints.add(new PVector(x0, y0));
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
          intersectionPoints.add(new PVector(x0, y0));
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
    PVector newLocation = new PVector((int)(location.x + velx),
                                      (int)(location.y + vely));
    PVector oldLocation = location;
    
    if ((Math.abs(lastBranch.x - newLocation.x) >= branchDistance) ||
        (Math.abs(lastBranch.y - newLocation.y) >= branchDistance))
    {
      lastBranch = newLocation;
      double branchAngle = random(branchAngleMaxRange - branchAngleMinRange) + branchAngleMinRange;
      Agent newAgent = new Agent(direction + branchAngle, speed, newLocation, branchDistance);
      nextStepAgents.add(newAgent);
    }

    location = newLocation;

    Boolean intersected = checkedLine(oldLocation, newLocation);

    PVector offset = new PVector(location.x - width / 2,
                                 location.y - height / 2);
    double distFromCenter = sqrt((offset.x * offset.x) + (offset.y * offset.y));

    if (distFromCenter <= (width / 2 - margin * 2))
    {
      if (!intersected)
      {
        nextStepAgents.add(this);
      }
    }

    return nextStepAgents;
  }
}

ArrayList<Agent> agents = new ArrayList<Agent>();
int stage = 0;
int stage1y = 0;

void setup()
{
  size(800, 800);
  noSmooth();
    
  int startCount = (int)(random(maxStartingAgents - minStartingAgents) + minStartingAgents);
  for (int i = 0; i < startCount; ++i)
  {
    Agent agent = new Agent(random(359), speed, new PVector(width / 2, height / 2), branchDist);
    agents.add(agent);
  }
}

void draw()
{
  if (stage == 0)
  {
    ArrayList<Agent> nextStepAgents = new ArrayList<Agent>();
    for (Agent agent : agents)
    {
      nextStepAgents.addAll(agent.step());
    }
    agents = nextStepAgents;
    
    if (agents.size() == 0)
    {
      stage = 1;
    }
  }
  else if (stage == 1)
  {
     double maxDistSq = width * width + height * height;
     
     loadPixels();
      int y = stage1y;
       for (int x = 0; x < width; ++x)
        {
            PVector closest = intersectionPoints.get(0);
            double closestDistSq = maxDistSq;
            for (PVector pt : intersectionPoints)
            {
                double distX = x - pt.x;
                double distY = y - pt.y;
                double distSq = distX * distX + distY * distY;
                if (distSq < closestDistSq)
                {
                    closest = pt;
                    closestDistSq = distSq;
                }
            }
            double distScale = Math.sqrt(closestDistSq) / maxCellSize;
            int c = (int)(distScale * 0xFF);
            if (c > 0xFF)
            {
              c = 0;
            }
            pixels[y * width + x] = color(c);
        }
        updatePixels();
    
    
    stage1y++;
    if (stage1y >= height)
    {
      noLoop();
      println("Done");
    }
  }
  
  saveFrame();
}