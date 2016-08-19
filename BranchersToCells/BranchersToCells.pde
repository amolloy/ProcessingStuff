import java.lang.Math.*;
import java.util.ArrayList;
import java.util.Comparator;

final int margin = 40;
final int branchAngleMinRange = -45;
final int branchAngleMaxRange = 45;
final int minStartingAgents = 2;
final int maxStartingAgents = 3;
final double speed = 10;
final double branchDist = 16;
final double maxCellSize = 50;

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
      
      PVector offset = new PVector(newLocation.x - width / 2,
                                   newLocation.y - height / 2);
      double distFromCenter = sqrt((offset.x * offset.x) + (offset.y * offset.y));
      if (distFromCenter <= (width / 2 - margin * 2))
      {
        double branchAngle = random(branchAngleMaxRange - branchAngleMinRange) + branchAngleMinRange;
        Agent newAgent = new Agent(direction + branchAngle, speed, newLocation, branchDistance);
        nextStepAgents.add(newAgent);
      }
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
KdTree kd_tree;

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
        kd_tree = new KdTree(intersectionPoints.toArray(new PVector[intersectionPoints.size()]));
        kd_tree.draw(this.g, !keyPressed, true,  0, 0, width, height);
        stage = 2;
    }
    else if (stage == 2)
    {
       loadPixels();
       for (int y = 0; y < height; ++ y)
       for (int x = 0; x < width; ++x)
       {
          PVector nearest = kd_tree.getNN( new PVector(x, y)).pnt_nn;
          double dist = Math.sqrt(pow(nearest.x - x, 2) + pow(nearest.y - y, 2));
          double distScale = dist / maxCellSize;
          int c = (int)(distScale * 0xFF);
          if (c > 0xFF)
          {
            c = 0;
          }
          pixels[y * width + x] = color(c);
        }
        updatePixels();

          noLoop();
          println("Done");
    }
  
    saveFrame();
}



 public static class KdTree
 {

    int max_depth = 0;
    KdTree.Node root;
    
    
    public KdTree(PVector[] points){
      max_depth = (int) Math.ceil( Math.log(points.length) / Math.log(2) );

      build( root = new KdTree.Node(0) , points);
      
//      if( numLeafs(root, 0) != points.length){
//        System.err.println("number of leafes doesnt match number of points");
//      }
    }

    
    
    //--------------------------------------------------------------------------
    // BUILD
    //--------------------------------------------------------------------------
    
    private final static Quicksort quick_sort = new Quicksort();
    //private final static Comparator<Point> SORT_X = new SortX();
    //private final static Comparator<Point> SORT_Y = new SortY();
    
    private void build(final KdTree.Node node, final PVector[] points){
      
      final int e = points.length;
      final int m = e>>1;

      if( e > 1 ){
        int depth = node.depth;
        //Arrays.sort(points, ((depth&1)==0)?SORT_X:SORT_Y);
        quick_sort.sort(points, depth&1); // faster than Arrays.sort() !
 
        build( (node.L = new Node(++depth)), copy(points, 0, m));
        build( (node.R = new Node(  depth)), copy(points, m, e));
      }
      node.pnt = points[m];
    }
    
    private final static PVector[] copy(final PVector[] src, final int a, final int b){
      final PVector[] dst = new PVector[b-a]; 
      System.arraycopy(src, a, dst, 0, dst.length);
      return dst;
//      return Arrays.copyOfRange(src, a, b); // a bit slower, but less verbose
    }

    
    
    
    //--------------------------------------------------------------------------
    // ANALYSIS
    //--------------------------------------------------------------------------
    
    public int numLeafs(KdTree.Node n, int num_leafs){
      if( n.isLeaf() ){
        return num_leafs+1;
      } else {
        num_leafs = numLeafs(n.L, num_leafs);
        num_leafs = numLeafs(n.R, num_leafs);
        return num_leafs;
      }
    }
    

    

    //--------------------------------------------------------------------------
    // DISPLAY
    //--------------------------------------------------------------------------
    
    public void draw(PGraphics g, boolean points, boolean planes, float x_min, float y_min, float x_max, float y_max){
      if( planes ) drawPlanes(g, root, x_min, y_min, x_max, y_max);
      if( points ) drawPoints(g, root);
    }
    
    public void drawPlanes(PGraphics g, KdTree.Node node, float x_min, float y_min, float x_max, float y_max ){
      if( node != null ){
        PVector pnt = node.pnt;
        if( (node.depth&1) == 0 ){
          drawPlanes(g, node.L, x_min, y_min, pnt.x, y_max);
          drawPlanes(g, node.R, pnt.x, y_min, x_max, y_max);
          drawLine  (g, node,   pnt.x, y_min, pnt.x, y_max);
        } else {
          drawPlanes(g, node.L, x_min, y_min, x_max, pnt.y);
          drawPlanes(g, node.R, x_min, pnt.y, x_max, y_max); 
          drawLine  (g, node,   x_min, pnt.y, x_max, pnt.y);
        }
      }
    }
    
    void drawLine(PGraphics g, KdTree.Node node, float x_min, float y_min, float x_max, float y_max){
      float dnorm = (node.depth)/(float)(max_depth+1);
      g.stroke(dnorm*150);
      g.strokeWeight( Math.max((1-dnorm)*5, 1) );
      g.line(x_min, y_min, x_max, y_max);
    }
    
    public void drawPoints(PGraphics g, KdTree.Node node){
      if( node.isLeaf() ){
        g.strokeWeight(1);g.stroke(0); g.fill(0,165,255);
        g.ellipse(node.pnt.x,node.pnt.y, 4, 4); 
      } else {
        drawPoints(g, node.L);
        drawPoints(g, node.R);
      }
    }
    

    
    
    
    
    //--------------------------------------------------------------------------
    // NEAREST-NEIGHBOR-SEARCH (NNS)
    //--------------------------------------------------------------------------
    
    public static class NN{
      PVector pnt_in = null;
      PVector pnt_nn = null;
      float min_sq = Float.MAX_VALUE;
      
      public NN(PVector pnt_in){
        this.pnt_in = pnt_in;
      }
      
      void update(Node node){
        
        float dx = node.pnt.x - pnt_in.x;
        float dy = node.pnt.y - pnt_in.y;
        float cur_sq = dx*dx + dy*dy;

        if( cur_sq < min_sq ){
          min_sq = cur_sq;
          pnt_nn = node.pnt;
        }
      }
      
    }
    
    public NN getNN(PVector point){
      NN nn = new NN(point);
      getNN(nn, root);
      return nn;
    }
    
    public NN getNN(NN nn, boolean reset_min_sq){
      if(reset_min_sq) nn.min_sq = Float.MAX_VALUE;
      getNN(nn, root);
      return nn;
    }
    
    private void getNN(NN nn, KdTree.Node node){
      if( node.isLeaf() ){
        nn.update(node);
      } else {
        float dist_hp = planeDistance(node, nn.pnt_in); 
        
        // check the half-space, the point is in.
        getNN(nn, (dist_hp < 0) ? node.L : node.R);
        
        // check the other half-space when the current distance (to the 
        // nearest-neighbor found so far) is greater, than the distance
        // to the other (yet unchecked) half-space's plane.
        if( (dist_hp*dist_hp) < nn.min_sq ){
          getNN(nn, (dist_hp < 0) ? node.R : node.L); 
        }
      }
    }
    
    private final float planeDistance(KdTree.Node node, PVector point){
      if( (node.depth&1) == 0){
        return point.x - node.pnt.x;
      } else {
        return point.y - node.pnt.y;
      }
    }
    
    
    //--------------------------------------------------------------------------
    // KD-TREE NODE
    //--------------------------------------------------------------------------
    /**
     * KdTree Node.
     * 
     * @author thomas diewald
     *
     */
    public static class Node{
      int depth;
      PVector pnt;
      Node L, R;
      
      public Node(int depth){
        this.depth = depth;
      }
      boolean isLeaf(){
        return (L==null) | (R==null); // actually only one needs to be teste for null.
      }
    }
    
  }
  
  
  
  
  
  //--------------------------------------------------------------------------
  // SOME SORTING
  //--------------------------------------------------------------------------
  
  public static final class SortX implements Comparator<PVector>{
    //@Override
    public int compare(final PVector a, final PVector b) {
      return (a.x < b.x) ? -1 : ((a.x > b.x)? +1 : 0);
    }
  }
  public static final class SortY implements Comparator<PVector>{
    //@Override
    public int compare(final PVector a, final PVector b) {
      return (a.y < b.y) ? -1 : ((a.y > b.y)? +1 : 0);
    }
  }
  
  
  public static class Quicksort  {
    private int dim = 0;
    private PVector[] points;
    private PVector points_t_;
    
    public void sort(PVector[] points, int dim) {
      if (points == null || points.length == 0) return;
      this.points = points;
      this.dim = dim;
      quicksort(0, points.length - 1);
    }

    private void quicksort(int low, int high) {
      int i = low, j = high;
      PVector pivot = points[low + ((high-low)>>1)];

      while (i <= j) {
        if( dim == 0 ){
          while (points[i].x < pivot.x) i++;
          while (points[j].x > pivot.x) j--;
        } else {
          while (points[i].y < pivot.y) i++;
          while (points[j].y > pivot.y) j--;
        }
        if (i <= j)  exchange(i++, j--);
      }
      if (low <  j) quicksort(low,  j);
      if (i < high) quicksort(i, high);
    }

    private void exchange(int i, int j) {
      points_t_ = points[i];
      points[i] = points[j];
      points[j] = points_t_;
    }
  } 
  
  