import java.lang.Math.*;
import java.util.ArrayList;

final double margin = 10;

class Point
{
  public double x, y;
  public Point(double x, double y)
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
  
  public ArrayList<Agent> step()
  {
    ArrayList<Agent> nextStepAgents = new ArrayList<Agent>();
    
    Point vel = new Point(Math.cos(Math.toRadians(direction)) * speed, 
                          Math.sin(Math.toRadians(direction)) * speed);
    Point newLocation = new Point(location.x + vel.x,
                                  location.y + vel.y);
    Point oldLocation = location;
    
    if ((Math.abs(lastBranch.x - newLocation.x) >= branchDistance) ||
        (Math.abs(lastBranch.y - newLocation.y) >= branchDistance))
    {
      lastBranch = newLocation;
      Agent newAgent = new Agent(direction + 90, speed, newLocation, branchDistance);
      nextStepAgents.add(newAgent);
    }

    location = newLocation;
    
    if ((location.x < (width - margin * 2)) &&
        (location.y < (height - margin * 2)) &&
        (location.x >= margin) &&
        (location.y >= margin) &&
        get((int)location.x, (int)location.y) != color(0))
    {
      nextStepAgents.add(this);
    }
                      
    line((float)oldLocation.x, (float)oldLocation.y, (float)newLocation.x, (float)newLocation.y);

    return nextStepAgents;
  }
}

ArrayList<Agent> agents = new ArrayList<Agent>();

void setup()
{
  size(800, 800);
  
  double speed = 5;
  double branchDist = 10;
  
  Agent agent = new Agent(90, speed, new Point(margin, margin), branchDist);
  agents.add(agent);
  agent = new Agent(0, speed, new Point(margin, margin), branchDist);
  agents.add(agent);
}

void draw()
{
  ArrayList<Agent> nextStepAgents = new ArrayList<Agent>();
  for (Agent agent : agents)
  {
    nextStepAgents.addAll(agent.step());
  }
  agents = nextStepAgents;
  
  if (agents.count() == 0)
  {
    noLoop();
  }
  
  saveFrame();
}