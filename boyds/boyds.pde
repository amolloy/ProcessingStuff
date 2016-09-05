import peasy.*;

final int numBirds = 500;
final int worldSize = 1000;
final float maxSpeed     = 100.0f;
final float minUrgency   = 40.0f;
final float maxUrgency   = 100.0f;
final float maxChange    = (maxSpeed * maxUrgency);
final float desiredSpeed = (maxSpeed / 2);

final float minFriendDist = 250;

final float nearbyDist = 500;
final float nearbyDistSq = nearbyDist * nearbyDist;
final float nearbyAngle = 120;
final float nearbyAngleRadians = nearbyAngle * PI / 180.0;

final color colors[] = {#FF15A9,
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

Boolean drawTracers = false;

PeasyCam camera;

Flock flock;
Bounds worldBounds = new Bounds(new PVector(-worldSize, worldSize, worldSize), 
  new PVector(worldSize, -worldSize, -worldSize));
int lastFrameTime;

void setup()
{
  size(800, 800, P3D);
  background(0);
  stroke(255, 255, 255, 128);

  camera = new PeasyCam(this, 0, 0, 0, 2000);

  flock = new Flock();
  for (int i = 0; i < numBirds; ++i)
  {
    PVector sPos = worldBounds.randomPointInBounds(250);
    PVector sVel = (new PVector(random(2) - 1, random(2) - 1, random(2) - 1)).normalize().mult(desiredSpeed);
    int colorIndex = int(random(colors.length));
    Bird bird = new Bird(sPos, 
      sVel, 
      desiredSpeed, 
      maxSpeed, 
      minUrgency, 
      maxUrgency, 
      minFriendDist,
      colors[colorIndex]);
    flock.birds.add(bird);
  }

  Bird bird = new Bird(new PVector(),
                       new PVector(),
                       desiredSpeed,
                       maxSpeed,
                       minUrgency,
                       maxUrgency,
                       minFriendDist,
                       #FF0000);
  bird.behaviors.add(new CircleBehavior(new PVector(), 450));
  flock.birds.add(bird);
  flock.leader = bird;

  flock.behaviors.add(new MatchHeadingBehavior());
  flock.behaviors.add(new CruisingBehavior());
  flock.behaviors.add(new KeepDistanceBehavior());
  flock.behaviors.add(new AvoidBoundsBehavior(worldBounds, 200));
  flock.behaviors.add(new FollowTheLeaderBehavior(flock.leader));

  lastFrameTime = millis();
}

void keyPressed()
{
  if (key == ' ')
  {
    drawTracers = !drawTracers;
    background(0);
  }
}

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

  if (!drawTracers)
  {
    background(0);
  }

//  frustum(-1.6, 1.6, -1.6, 1.6, 4, worldSize * 10);
//  camera(0, 0, -worldSize * 3, 0, 0, 0, 0, 1, 0);

//  worldBounds.draw();

  float alphaRange = abs(worldBounds.back() - worldBounds.front());

  if (drawTracers)
  {
    for (Bird b : flock.birds)
    {
      if (b != flock.leader)
      {
        float alpha = b.pos.z / alphaRange;
        alpha = max(0, min(alpha, 0.75));
        
        fill(b.c, (1 - alpha) * 0xFF);
        noStroke();
        float[] lookatA = camera.getLookAt();
        PVector lookat = new PVector(lookatA[0], lookatA[1], lookatA[2]);
        float[] posA = camera.getPosition();
        PVector pos = new PVector(posA[0], posA[1], posA[2]);
        litLine(b.oldPos, b.pos, 10, PVector.sub(pos, lookat));
//        strokeWeight(4);
//        line(b.oldPos.x, b.oldPos.y, b.oldPos.z, b.pos.x, b.pos.y, b.pos.z);
      }
    }
  }
  else
  {
    for (Bird b : flock.birds)
    {
      stroke(b.c);
      pushMatrix();
      translate(b.pos.x, b.pos.y, b.pos.z);
      box(4);
      popMatrix();
    }
  }
  int m = millis();
  int delta = m - lastFrameTime;
  float deltaS = delta / 1000.0;
  flock.update(deltaS);
  lastFrameTime = m;
  
  //noLoop();
}

class Bounds
{
  private final PVector leftBottomBack;
  private final PVector rightTopFront;

  Bounds(PVector leftBottomBack, PVector rightTopFront)
  {
    this.leftBottomBack = leftBottomBack;
    this.rightTopFront = rightTopFront;
  }

  PVector randomPointInBounds(float margin)
  {
    return new PVector(random(left() + margin, right() - margin), 
      random(top() + margin, bottom() - margin), 
      random(front() + margin, back() - margin));
  }

  float front()
  {
    return rightTopFront.z;
  }
  float back()
  {
    return leftBottomBack.z;
  }
  float left()
  {
    return leftBottomBack.x; //<>//
  }
  float right()
  {
    return rightTopFront.x;
  }
  float top()
  {
    return rightTopFront.y;
  }
  float bottom()
  {
    return leftBottomBack.y;
  }

  final PVector leftBottomFront()
  {
    return new PVector(leftBottomBack.x, leftBottomBack.y, rightTopFront.z);
  }
 //<>//
  final PVector leftTopFront()
  {
    return new PVector(leftBottomBack.x, rightTopFront.y, rightTopFront.z);
  }

  final PVector leftTopBack()
  {
    return new PVector(leftBottomBack.x, rightTopFront.y, leftBottomBack.z);
  }

  final PVector leftBottomBack()
  {
    return leftBottomBack.copy();
  }

  final PVector rightBottomFront()
  {
    return new PVector(rightTopFront.x, leftBottomBack.y, rightTopFront.z);
  }

  final PVector rightTopFront()
  {
    return rightTopFront.copy();
  }

  final PVector rightTopBack()
  {
    return new PVector(rightTopFront.x, rightTopFront.y, leftBottomBack.z);
  }

  final PVector rightBottomBack()
  {
    return new PVector(rightTopFront.x, leftBottomBack.y, leftBottomBack.z);
  }

  void line2(PVector p1, PVector p2)
  {
    line(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z);
  }

  void draw()
  {
    line2(leftTopBack(), rightTopBack());
    line2(leftTopBack(), leftTopFront());
    line2(leftTopFront(), rightTopFront());
    line2(rightTopBack(), rightTopFront());
    line2(leftTopBack(), leftBottomBack());
    line2(rightTopBack(), rightBottomBack());
    line2(leftTopFront(), leftBottomFront());
    line2(rightTopFront(), rightBottomFront());
    line2(leftBottomBack(), rightBottomBack());
    line2(leftBottomBack(), leftBottomFront());
    line2(rightBottomBack(), rightBottomFront());
    line2(leftBottomFront(), rightBottomFront());
  }
}

public static interface BirdBehavior
{
  PVector steeringContribution(Bird boyd, ArrayList<Bird> nearbyBirds);
}

class Bird
{
  PVector pos;
  PVector vel;
  PVector oldPos;
  PVector oldVel;
  ArrayList<BirdBehavior> behaviors;
  final float desiredSpeed;
  final float maxSpeed;
  final float minUrgency;
  final float maxUrgency;
  final float minFriendDistance;
  color c;

  Bird(PVector inPos, 
    PVector inVel, 
    float desiredSpeed, 
    float maxSpeed, 
    float minUrgency, 
    float maxUrgency, 
    float minFriendDistance, 
    color c)
  {
    this.pos = inPos.copy();
    this.vel = inVel.copy();
    this.desiredSpeed = desiredSpeed;
    this.maxSpeed = maxSpeed;
    this.minUrgency = minUrgency;
    this.maxUrgency = maxUrgency;
    this.minFriendDistance = minFriendDistance;
    pushPositionAndVelocity();
    behaviors = new ArrayList();
    this.c = c;
  }

  void pushPositionAndVelocity()
  {
    oldPos = pos.copy();
    oldVel = vel.copy();
  }

  Boolean canSeeBird(Bird otherBird)
  {
    Boolean csb = ((this != otherBird) &&
      (this.oldPos.copy().sub(otherBird.oldPos).magSq() < nearbyDistSq) &&
      (abs(this.oldVel.heading() - otherBird.oldVel.heading()) < nearbyAngleRadians));
      
    return csb;
  }
}

class Flock
{
  ArrayList<Bird> birds;
  ArrayList<BirdBehavior> behaviors;
  Bird leader;

  Flock()
  {
    birds = new ArrayList();
    behaviors = new ArrayList();
    leader = null;
  }

  void update(float elapsed)
  {
    for (Bird b : birds)
    {
      b.pushPositionAndVelocity();
    }

    for (Bird b : birds)
    {
      ArrayList<Bird> nearbyBirds = new ArrayList<Bird>(birds.size());

      for (Bird b1 : birds)
      {
        if (b.canSeeBird(b1))
        {
          nearbyBirds.add(b1);
        }
      }

      PVector steering = new PVector();

      if (b != leader)
      {
        for (BirdBehavior behavior : behaviors)
        {
          steering.add(behavior.steeringContribution(b, nearbyBirds));
        }
      }

      for (BirdBehavior behavior : b.behaviors)
      {
        steering.add(behavior.steeringContribution(b, nearbyBirds));
      }

      steering.limit(maxChange);

      b.vel.add(steering);
      b.vel.limit(maxSpeed);
      b.pos.add(b.vel.copy().mult(elapsed));
    }
  }
}

class AvoidBoundsBehavior implements BirdBehavior
{
  class Plane
  {
    PVector normal;
    PVector point;

    String toString()
    {
      return "Plane: " + normal + " point: " + point;
    }
  }
  Plane planes[];
  float minPreferedDistance;

  Plane planeWithPoints(PVector a, PVector b, PVector c)
  {
    PVector ab = PVector.sub(b, a);
    PVector ac = PVector.sub(c, a);

    Plane p = new Plane();
    p.normal = ab.cross(ac);
    p.normal.normalize();
    //println(p.normal,  -(p.normal.x * a.x + p.normal.y * a.y + p.normal.z * a.z));
    p.point = a.copy();

    return p;
  }

  AvoidBoundsBehavior(Bounds bounds, float minPreferedDistance)
  {
    planes = new Plane[6];
    planes[0] = planeWithPoints(bounds.rightTopFront(), bounds.rightBottomFront(), bounds.leftTopFront());
    planes[1] = planeWithPoints(bounds.rightTopFront(), bounds.leftTopFront(), bounds.rightTopBack());
    planes[2] = planeWithPoints(bounds.rightTopBack(), bounds.leftTopBack(), bounds.rightBottomBack());
    planes[3] = planeWithPoints(bounds.rightBottomBack(), bounds.leftBottomBack(), bounds.rightBottomFront());
    planes[4] = planeWithPoints(bounds.leftTopBack(), bounds.leftTopFront(), bounds.leftBottomBack());
    planes[5] = planeWithPoints(bounds.rightTopBack(), bounds.rightBottomBack(), bounds.rightTopFront());
    this.minPreferedDistance = minPreferedDistance;
  }

  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    PVector steering = new PVector();
    for (Plane p : planes)
    {
      float dist = PVector.dot(p.normal, PVector.sub(bird.oldPos, p.point));
      if (dist <= minPreferedDistance)
      {
        float ratio = (minPreferedDistance - dist) / minPreferedDistance;
        steering.add(PVector.mult(p.normal, ratio));
      }
    }

    return steering;
  }
}

class MatchHeadingBehavior implements BirdBehavior
{
  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    PVector change = new PVector();
    for (Bird b : nearbyBirds)
    {
      change.add(b.oldVel);
    }
    change.normalize().mult(minUrgency);

    return change;
  }
}

class FollowTheLeaderBehavior implements BirdBehavior
{
  Bird leader;
  
  FollowTheLeaderBehavior(Bird leader)
  {
    this.leader = leader;
  }
  
  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    PVector change = PVector.sub(leader.oldPos, bird.oldPos);
    change.normalize().mult(minUrgency * 0.9);
    return change;
  }
}

class CruisingBehavior implements BirdBehavior
{
  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    float desiredSpeed = bird.desiredSpeed;

    PVector change = bird.oldVel.copy();
    final float startingSpeed = change.mag();

    float diff = (startingSpeed - desiredSpeed) / bird.maxSpeed;
    float sign = diff >= 0 ? 1 : -1;

    float urgency = abs(diff);

    urgency = min(urgency, bird.maxUrgency);
    urgency = max(urgency, bird.minUrgency);

    change.normalize().mult(urgency * sign);

    return change;
  }
}

class KeepDistanceBehavior implements BirdBehavior
{
  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    Bird closestFriend = null;
    float minDistSq = 0;

    for (Bird b : nearbyBirds)
    {
      if (closestFriend == null)
      {
        closestFriend = b;
        minDistSq = PVector.sub(closestFriend.oldPos, bird.oldPos).magSq();
      } 
      else
      {
        float distSq = PVector.sub(b.oldPos, bird.oldPos).magSq();
        if (distSq < minDistSq)
        {
          closestFriend = b;
          minDistSq = distSq;
        }
      }
    }

    if (closestFriend == null) //<>//
    {
      return new PVector();
    }

    float minDist = sqrt(minDistSq);
    float ratio = minDist / bird.minFriendDistance;

    PVector change = PVector.sub(closestFriend.oldPos, bird.oldPos);

    if (ratio < bird.minUrgency) //<>//
    {
      ratio = bird.minUrgency;
    }
    if (ratio > bird.maxUrgency)
    {
      ratio = bird.maxUrgency;
    }

    if (minDist < bird.minFriendDistance)
    {
      change.normalize().mult(-ratio);
    } 
    else if (minDist > bird.minFriendDistance)
    {
      change.normalize().mult(ratio);
    } 
    else
    {
      change.mult(0);
    }
  
    return change;
  }
}

class CircleBehavior implements BirdBehavior
{
  PVector center;
  float radius;
  
  CircleBehavior(PVector center, float radius)
  {
    this.center = center;
    this.radius = radius;
  }
 
  PVector steeringContribution(Bird bird, ArrayList<Bird> nearbyBirds)
  {
    PVector oldPosXY = bird.oldPos.copy();
    oldPosXY.z = 0;
    PVector centerXY = center.copy();
    centerXY.z = 0;

    PVector steering = new PVector();

    PVector d = PVector.sub(oldPosXY, centerXY);
    float distanceFromCircle = d.mag();
    if (distanceFromCircle < radius)
    {
      steering.add(PVector.sub(oldPosXY, new PVector(centerXY.x, centerXY.y + 1, centerXY.z)));
    }
    else if (distanceFromCircle > radius * 1.1)
    {
      float a = asin(radius / distanceFromCircle);
      float b = atan2(d.y, d.x);
      float t = b - a;
      PVector ta = new PVector(radius * sin(t), radius * -cos(t), centerXY.z);
      
      PVector dta = PVector.sub(ta, oldPosXY);
      
      steering = dta;
    }
    else
    {
      steering = PVector.sub(oldPosXY, centerXY);
    }
    
    float distFromPlane = bird.oldPos.z - center.z;
    if (distFromPlane > 10)
    {
      steering.sub(0, 0, distFromPlane);
    }

    steering.normalize().mult(bird.desiredSpeed);
    
    //println(distanceFromCircle, distFromPlane, steering);
    
    return steering;
  }
}