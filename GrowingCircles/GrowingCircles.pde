import java.util.Comparator;
import java.util.Collections;

int startingCircleCount = 5000;

final color crayonColors[] = {#FF15A9,
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

final color rainColors[] = {#6FCFFF,
#003666,
#006666,
#1FB0C3,
#DBDBDB
};

final color colors[] = rainColors;


PShader radialGradient;

class Circle
{
  Circle(PVector center, color c, int radius)
  {
    this.center = center.copy();
    this.c = c;
    this.radius = radius;
  }
  Circle(PVector center, color c)
  {
    this(center, c, 0);
  }

  PVector center;
  int radius;
  color c;

  void draw()
  {
    float r = (c >> 16 & 0xFF) / (float)0xFF;
    float g = (c >> 8 & 0xFF) / (float)0xFF;
    float b = (c & 0xFF) / (float)0xFF;
    
    noStroke();
    shader(radialGradient);

    radialGradient.set("innerColor", r, g, b, 1);
    radialGradient.set("outerColor", r, g, b, 0);
    radialGradient.set("radius", (float)max(radius, 1));
  
    fill(0);
    rect(center.x - radius, center.y - radius, radius * 2, radius * 2);
  }
}

KdTree tree = null;
HashMap<PVector, Circle> circles = new HashMap();
ArrayList<Circle> oldCircles = new ArrayList();

void setup()
{
  size(800, 800, P2D);
  background(0);

  radialGradient = loadShader("RadialGradient.frag.glsl", "RadialGradient.vert.glsl");

  for (int i = 0; i < startingCircleCount; ++i)
  {
    int colorIndex = i % colors.length;
    color c = colors[colorIndex];
    Circle newCircle = new Circle(new PVector(random(0, width), random(0, height)), c);
    circles.put(newCircle.center, newCircle);
  }
}

void rebuildTree()
{
  PVector[] centers = new PVector[circles.size()];
  int i = 0;
  for (Circle c : circles.values())
  {
    centers[i] = c.center;
    i+= 1;
  }

  tree = new KdTree(centers);
}

void draw()
{
  if (tree == null)
  {
    rebuildTree();
  }

  Boolean treeNeedsRebuilding = false;

  ArrayList<Circle> circlesToRemove = new ArrayList();
  ArrayList<Circle> circlesToAdd = new ArrayList();

  for (Circle c : circles.values())
  {
    if (!circlesToRemove.contains(c))
    {
      ArrayList<PVector> nearestCenters = tree.getNN(c.center).pnt_nn;
      Circle overlappingCircle = null;
      float dist = 0;
      for (PVector v : nearestCenters)
      {
        dist = PVector.dist(c.center, v);
        overlappingCircle = circles.get(v);
        if (dist < (c.radius + overlappingCircle.radius))
        {
          break;
        }

        overlappingCircle = null;
      }

      if (overlappingCircle == null)
      {
        continue;
      }

      treeNeedsRebuilding = true;

      oldCircles.add(c);
      oldCircles.add(overlappingCircle);

      circlesToRemove.add(c);
      circlesToRemove.add(overlappingCircle);

      PVector p0 = c.center.copy();
      PVector p1 = overlappingCircle.center.copy();
      float d = PVector.dist(p0, p1);
      float a = (c.radius * c.radius - overlappingCircle.radius * overlappingCircle.radius + d * d) / (2 * d);

      PVector s1 = PVector.sub(p1, p0);
      PVector s2 = s1.mult(a / d);
      PVector p2 = PVector.add(p0, s2);

      color col;
      if (c.radius < overlappingCircle.radius)
      {
        col = c.c;
      }
      else
      {
        col = overlappingCircle.c;
      }

      circlesToAdd.add(new Circle(p2, col));
    }
  }

  for (Circle c : circlesToRemove)
  {
    circles.remove(c.center);
  }
  for (Circle c : circlesToAdd)
  {
    circles.put(c.center, c);
  }

  if (circles.size() == 1)
  {
    circles.clear();
    noLoop();
    println("Done");
    save("circles.jpg");
    return;
  }

  background(0);
  noFill();
  stroke(255, 128);
  ArrayList<Circle> allCircles = new ArrayList(circles.values());
  allCircles.addAll(oldCircles);
  Collections.sort(allCircles, new Comparator<Circle>() {
    @Override
        public int compare(Circle c1, Circle c2)
        {
          return c2.radius - c1.radius;
        }
  });
  
  for (Circle c : allCircles)
  {
    c.draw();
  }

  for (Circle c : circles.values())
  {
    c.radius += 1;
  }

  if (treeNeedsRebuilding)
  {
    tree = null;
  }
}

public static class KdTree
{
  int max_depth = 0;
  KdTree.Node root;


  public KdTree(PVector[] points) {
    max_depth = (int) Math.ceil( Math.log(points.length) / Math.log(2) );

    build( root = new KdTree.Node(0), points);

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

  private void build(final KdTree.Node node, final PVector[] points) {

    final int e = points.length;
    final int m = e>>1;

    if ( e > 1 ) {
      int depth = node.depth;
      //Arrays.sort(points, ((depth&1)==0)?SORT_X:SORT_Y);
      quick_sort.sort(points, depth&1); // faster than Arrays.sort() !

      build( (node.L = new Node(++depth)), copy(points, 0, m));
      build( (node.R = new Node(  depth)), copy(points, m, e));
    }
    node.pnt = points[m];
  }

  private final static PVector[] copy(final PVector[] src, final int a, final int b) {
    final PVector[] dst = new PVector[b-a]; 
    System.arraycopy(src, a, dst, 0, dst.length);
    return dst;
    //      return Arrays.copyOfRange(src, a, b); // a bit slower, but less verbose
  }




  //--------------------------------------------------------------------------
  // ANALYSIS
  //--------------------------------------------------------------------------

  public int numLeafs(KdTree.Node n, int num_leafs) {
    if ( n.isLeaf() ) {
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

  public void draw(PGraphics g, boolean points, boolean planes, float x_min, float y_min, float x_max, float y_max) {
    if ( planes ) drawPlanes(g, root, x_min, y_min, x_max, y_max);
    if ( points ) drawPoints(g, root);
  }

  public void drawPlanes(PGraphics g, KdTree.Node node, float x_min, float y_min, float x_max, float y_max ) {
    if ( node != null ) {
      PVector pnt = node.pnt;
      if ( (node.depth&1) == 0 ) {
        drawPlanes(g, node.L, x_min, y_min, pnt.x, y_max);
        drawPlanes(g, node.R, pnt.x, y_min, x_max, y_max);
        drawLine  (g, node, pnt.x, y_min, pnt.x, y_max);
      } else {
        drawPlanes(g, node.L, x_min, y_min, x_max, pnt.y);
        drawPlanes(g, node.R, x_min, pnt.y, x_max, y_max); 
        drawLine  (g, node, x_min, pnt.y, x_max, pnt.y);
      }
    }
  }

  void drawLine(PGraphics g, KdTree.Node node, float x_min, float y_min, float x_max, float y_max) {
    float dnorm = (node.depth)/(float)(max_depth+1);
    g.stroke(dnorm*150);
    g.strokeWeight( Math.max((1-dnorm)*5, 1) );
    g.line(x_min, y_min, x_max, y_max);
  }

  public void drawPoints(PGraphics g, KdTree.Node node) {
    if ( node.isLeaf() ) {
      g.strokeWeight(1);
      g.stroke(0); 
      g.fill(0, 165, 255);
      g.ellipse(node.pnt.x, node.pnt.y, 4, 4);
    } else {
      drawPoints(g, node.L);
      drawPoints(g, node.R);
    }
  }






  //--------------------------------------------------------------------------
  // NEAREST-NEIGHBOR-SEARCH (NNS)
  //--------------------------------------------------------------------------

  public static class NN {
    PVector pnt_in = null;
    ArrayList<PVector> pnt_nn = new ArrayList();
    float min_sq = Float.MAX_VALUE;

    public NN(PVector pnt_in) {
      this.pnt_in = pnt_in;
    }

    void update(Node node) {

      float dx = node.pnt.x - pnt_in.x;
      float dy = node.pnt.y - pnt_in.y;
      float cur_sq = dx*dx + dy*dy;

      if ( cur_sq < min_sq && cur_sq != 0) {
        min_sq = cur_sq;
        pnt_nn.add(node.pnt);
      }
    }
  }

  public NN getNN(PVector point) {
    NN nn = new NN(point);
    getNN(nn, root);
    return nn;
  }

  public NN getNN(NN nn, boolean reset_min_sq) {
    if (reset_min_sq) nn.min_sq = Float.MAX_VALUE;
    getNN(nn, root);
    return nn;
  }

  private void getNN(NN nn, KdTree.Node node) {
    if ( node.isLeaf() ) {
      nn.update(node);
    } else {
      float dist_hp = planeDistance(node, nn.pnt_in); 

      // check the half-space, the point is in.
      getNN(nn, (dist_hp < 0) ? node.L : node.R);

      // check the other half-space when the current distance (to the 
      // nearest-neighbor found so far) is greater, than the distance
      // to the other (yet unchecked) half-space's plane.
      if ( (dist_hp*dist_hp) < nn.min_sq ) {
        getNN(nn, (dist_hp < 0) ? node.R : node.L);
      }
    }
  }

  private final float planeDistance(KdTree.Node node, PVector point) {
    if ( (node.depth&1) == 0) {
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
  public static class Node {
    int depth;
    PVector pnt;
    Node L, R;

    public Node(int depth) {
      this.depth = depth;
    }
    boolean isLeaf() {
      return (L==null) | (R==null); // actually only one needs to be teste for null.
    }
  }
}





//--------------------------------------------------------------------------
// SOME SORTING
//--------------------------------------------------------------------------

public static final class SortX implements Comparator<PVector> {
  //@Override
  public int compare(final PVector a, final PVector b) {
    return (a.x < b.x) ? -1 : ((a.x > b.x)? +1 : 0);
  }
}
public static final class SortY implements Comparator<PVector> {
  //@Override
  public int compare(final PVector a, final PVector b) {
    return (a.y < b.y) ? -1 : ((a.y > b.y)? +1 : 0);
  }
}


public static class Quicksort {
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
      if ( dim == 0 ) {
        while (points[i].x < pivot.x) i++;
        while (points[j].x > pivot.x) j--;
      } else {
        while (points[i].y < pivot.y) i++;
        while (points[j].y > pivot.y) j--;
      }
      if (i <= j)  exchange(i++, j--);
    }
    if (low <  j) quicksort(low, j);
    if (i < high) quicksort(i, high);
  }

  private void exchange(int i, int j) {
    points_t_ = points[i];
    points[i] = points[j];
    points[j] = points_t_;
  }
} 