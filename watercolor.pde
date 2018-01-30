ArrayList<PVector> rpoly(float x, float y, float r, int nsides) {
  ArrayList<PVector> points = new ArrayList<PVector>();
  float sx, sy;
  float angle = TWO_PI / nsides;
  
  /* Iterate over edges in a pairwise fashion. */
  for (float a = 0; a < TWO_PI; a += angle) {
    sx = x + cos(a) * r;
    sy = y + sin(a) * r;
    points.add(new PVector(sx, sy));
  }
  return points;
}

ArrayList<PVector> deform(ArrayList<PVector> points, int depth,
                            float variance, float vdiv) {
  float sx1, sy1, sx2 = 0, sy2 = 0;
  ArrayList<PVector> new_points = new ArrayList<PVector>();
  
  if (points.size() < 2)
    return new_points;

  /* Iterate over existing edges in a pairwise fashion. */
  for (int i = 0; i < points.size(); i++) {
    sx1 = points.get(i).x;
    sy1 = points.get(i).y;
    sx2 = points.get((i + 1) % points.size()).x;
    sy2 = points.get((i + 1) % points.size()).y;

    new_points.add(new PVector(sx1, sy1));
    subdivide(new_points, sx1, sy1, sx2, sy2, depth, variance, vdiv);
  }
  //new_points.add(new PVector(sx2, sy2));
  
  return new_points;
}

/*
 * Recursively subdivide a line from (x1, y1) to (x2, y2) to a
 * given depth using a specified variance.
 */
void subdivide(ArrayList<PVector> new_points,
                 float x1, float y1, float x2, float y2,
                 int depth, float variance, float vdiv) {
  float midx, midy;
  float nx, ny;

  if (depth >= 0) {
    /* Find the midpoint of the two points comprising the edge */
    midx = (x1 + x2) / 2;
    midy = (y1 + y2) / 2;

    /* Move the midpoint by a Gaussian variance */
    nx = midx + randomGaussian() * variance;
    ny = midy + randomGaussian() * variance;

    /* Add two new edges which are recursively subdivided */
    subdivide(new_points, x1, y1, nx, ny, depth - 1, random(variance/vdiv), vdiv);
    new_points.add(new PVector(nx, ny));
    subdivide(new_points, nx, ny, x2, y2, depth - 1, random(variance/vdiv), vdiv);
  }
}

void draw_poly(ArrayList<PVector> p) {
  beginShape();
  for (int i = 0; i < p.size(); i++)
    vertex(p.get(i).x, p.get(i).y);
  endShape(CLOSE);
}

ArrayList<ArrayList<PVector>> polystack(float x, float y, float r, int nsides) {
  ArrayList<ArrayList<PVector>> stack = new ArrayList<ArrayList<PVector>>();
  ArrayList<PVector> base_poly, poly;
  
  base_poly = rpoly(x, y, r, nsides);
  base_poly = deform(base_poly, 5, 15, 2);
  long seed = int(random(1000)); 
  for (int k = 0; k < 100; k++) {
    noiseSeed(seed);
    poly = deform(base_poly, 5, random(r/10, r/4), 4);
    stack.add(poly);
  }
  return stack;
}

void draw_stack(ArrayList<ArrayList<PVector>> stack) {
  for (int i = 0; i < stack.size(); i++) {
    ArrayList<PVector> poly = stack.get(i);
    draw_poly(poly);
  }
}

void gridline(float x1, float y1, float x2, float y2) {
  float tmp;
  if (x1 > x2) { tmp = x1; x1 = x2; x2 = tmp; tmp = y1; y1 = y2; y2 = tmp; }
  //if (y1 > y2) { tmp = y1; y1 = y2; y2 = tmp; }
  
  float dx = x2 - x1;
  float dy = y2 - y1;
  float step = 1;
  
  if (x2 < x1)
    step = -step;
  
  float sx = x1;
  float sy = y1;
  for (float x = x1+step; x <= x2; x+=step) {
    float y = y1 + step * dy * (x - x1) / dx;
    strokeWeight(1 + map(noise(sx, sy), 0, 1, -0.5, 0.5));
    line(sx, sy, x + map(noise(x, y), 0, 1, -1, 1), y + map(noise(x, y), 0, 1, -1, 1));
    sx = x;
    sy = y;
  }
}

void grid() {
  float spacing = 5;
  for (int i = -width; i < height + width; i+=spacing) {
    stroke(255, random(20, 50));
    gridline(i, 0, i + height, height);
  }
  for (int i = height + width; i >= -width; i-=spacing) {
    stroke(255, random(20, 50));
    gridline(i, 0, i - height, height);
  }
}

ArrayList<PVector> create_base_poly(float x, float y, float r, int nsides) {
  ArrayList<PVector> bp;
  bp = rpoly(x, y, r, nsides);
  bp = deform(bp, 5, r/10, 1);
  return bp;
}

void stacklist_add(
  ArrayList< ArrayList< ArrayList< PVector > > > stacklist,
  ArrayList< ArrayList< PVector > > stack, color c) {
  stacklist.add(stack);
  colors[color_index++] = c;
}

void stacklist_draw(
  ArrayList< ArrayList< ArrayList< PVector > > > stacklist,
  int[] colors,
  int interleave) {
  int layer = 0;
  boolean all_empty;
  
  while (true) {
    all_empty = true;
    println("drawing layers " + layer + "--" + (layer+interleave));
    for (int i = 0; i < stacklist.size(); i++) {
      fill(colors[i]);
      println("stacklist " + i + " using color " + colors[i]);
      ArrayList<ArrayList<PVector>> stack = stacklist.get(i);
      for (int j = layer; j < layer + interleave; j++) {
        if (j < stack.size()) {
          all_empty = false;
          draw_poly(stack.get(j));
        }
      }
    }
    layer += interleave;
    if (all_empty)
      break;
  }
}

ArrayList<PVector> poly, base_poly;
ArrayList<ArrayList<ArrayList<PVector>>> stacklist;
int[] colors;
int color_index = 0;

void setup() {
  ArrayList<ArrayList<PVector>> stack1, stack2;
  
  size(500, 500);
  
  stacklist = new ArrayList<ArrayList<ArrayList<PVector>>>();
  
  background(255);
  noStroke();
  //fill(255, 0, 0);
  //base_poly = create_base_poly(width/2, height/2, width/3, 10);
  //draw_poly(base_poly);
  //grid();
  //gen();
  
  stacklist = new ArrayList<ArrayList<ArrayList<PVector>>>();
  colors = new int[1000]; /* Up to 1,000 polygon stacks */

  stack1 = polystack(width/3, height/2, width/3, 10);
  stack2 = polystack(2*width/3, height/2, width/3, 10);

  stacklist_add(stacklist, stack1, color(255, 0, 0, 4));
  stacklist_add(stacklist, stack2, color(0, 0, 255, 4));

  stacklist_draw(stacklist, colors, 5);
  
  grid();
}

//void gen() {
//  background(255);
//  noStroke();
//  colors = new int[1000];
//  colors[color_index++] = color(255, 0, 0, 4);
//  stack = polystack(width/2, height/2, width/3, 10);
//  draw_stack(stack);
//}

void draw() {}

void mouseClicked() {
  //gen();
}

void keyPressed() {
  if (key == 's') {
    saveFrame();
  }
}