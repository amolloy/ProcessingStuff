int closedLoopProbability = 50; // Sort of how likely the character will be a closed loop. 
int cellWidth = 50;
int cellHeight = 80;
int margin = 10;
int cellXCount = 20;
int cellYCount = 10;
int fullCellWidth = cellWidth + margin * 2;
int fullCellHeight = cellHeight + margin * 2;

PVector segIntersection(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4) 
{ 
  float bx = x2 - x1; 
  float by = y2 - y1; 
  float dx = x4 - x3; 
  float dy = y4 - y3;
  float b_dot_d_perp = bx * dy - by * dx;
  if (b_dot_d_perp == 0) {
    return null;
  }
  float cx = x3 - x1;
  float cy = y3 - y1;
  float t = (cx * dy - cy * dx) / b_dot_d_perp;
  if (t < 0 || t > 1) {
    return null;
  }
  float u = (cx * by - cy * bx) / b_dot_d_perp;
  if (u < 0 || u > 1) { 
    return null;
  }
  return new PVector(x1+t*bx, y1+t*by);
}

void setup()
{
  size(1400,1000,P2D);
  int seed = (int)random(23039203);
  println("Seed: " + seed);

  // I thought 21956542 produced some nice things
  randomSeed(seed); // Replace "seed" here with the number printed above if you want to repeat a run

  //size(fullCellWidth * cellXCount, fullCellHeight * cellYCount, P2D);
  noFill();
  strokeWeight(0.5);
  int factor = cellWidth + margin * 2;
  for (int i = 0; i < cellXCount; ++i)
  {
    line(i * factor, 0, i * factor, fullCellHeight * cellYCount);
  }
  factor = cellHeight + margin * 2;
  for (int i = 0; i < cellYCount; ++i)
  {
    line(0, i * factor, fullCellWidth * cellXCount, i * factor);
  }
}

int iteration = 0;

void draw()
{
  noFill();
  strokeWeight(4);

  int offsetX = (iteration % cellXCount) * fullCellWidth;
  int offsetY = floor(iteration / cellXCount) * fullCellHeight;

  pushMatrix();
  translate(offsetX + margin, offsetY + margin);

  int count = (int)random(5) + 3;

  PVector[] pts = new PVector[count];

  boolean good = true;
  do
  {
    int algo = (int)(2 * random(1));

    if (true || algo == 0)
    {
      for (int i = 0; i < count; ++i)
      {
        pts[i] = new PVector();
        pts[i].x = cellWidth * random(1);
        pts[i].y = cellHeight * random(1);
      }
    }
    else if (algo == 1)
    {
      // This algorithm didn't give very interesting results, but feel free to try it by getting rid of the "true ||" in the if statement above
      pts[0] = new PVector();
      pts[0].x = cellWidth * random(1);
      pts[0].y = cellHeight * random(1);
      
      for (int i = 1; i < count; ++i)
      {
        pts[i] = new PVector();
        pts[i].x = pts[i - 1].x + random(50) - 25;
        pts[i].y = pts[i - 1].y + random(50) - 25;
        
        if (pts[i].x < 0) { pts[i].x = 0; }
        if (pts[i].x > cellWidth) { pts[i].x = cellWidth; }
        if (pts[i].y < 0) { pts[i].y = 0; }
        if (pts[i].y > cellHeight) { pts[i].y = cellHeight; }
      }
    }
    else
    {
      println("Oops!");
      noLoop();
    }

    for (int i = 1; i < count; ++i)
    {
      for ( int j = i + 2; j < count; ++j)
      {
        PVector intersect = segIntersection(pts[i - 1].x, pts[i - 1].y, pts[i].x, pts[i].y, pts[j - 1].x, pts[j - 1].y, pts[j].x, pts[j].y);
        if (null != intersect)
        {
          good = random(100) > 90; // allow a few self-intersections
          if (!good)
          {
            break;
          }
        }
      }
    }
  }
  while (!good);

  beginShape();

  vertex(pts[0].x, pts[0].y);
  for (int i = 2; i < count; ++i)
  {
    quadraticVertex(pts[i - 1].x, pts[i - 1].y, pts[i].x, pts[i].y);
  }

  if (random(100) <= closedLoopProbability)
  {
    quadraticVertex(pts[count - 1].x, pts[count - 1].y, pts[0].x, pts[0].y);
  }

  endShape();

  popMatrix();

  ++iteration;
  if (iteration > 200)
  {
    noLoop();
    saveFrame();
  }
}