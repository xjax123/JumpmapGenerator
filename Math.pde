public float normalize(float val, float min, float max) {
    return (val - min)/(max - min);
}

public float distance(int x1, int x2, int y1, int y2) {
    int xd = x1 - x2;
    int yd = y1 - y2;
    float dist = (float) Math.sqrt(xd*xd + yd*yd);
    return dist;
}

public float clamp(float val, float min, float max) {
    float temp;
    if (val < min) {
        temp = min;
    } else if (val > max) {
        temp = max;
    } else {
        temp = val;
    }
    return temp;
}

public float shunt(float val, float min, float max) {
    float temp;
    if (val > min) {
        temp = max;
    } else {
        temp = min;
    }
    return temp;
}

static boolean onSegment(PVector p, PVector q, PVector r) 
{ 
    if (q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) && 
        q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y)) 
    return true; 
  
    return false; 
} 
  
// To find orientation of ordered triplet (p, q, r). 
// The function returns following values 
// 0 --> p, q and r are collinear 
// 1 --> Clockwise 
// 2 --> Counterclockwise 
static float orientation(PVector p, PVector q, PVector r) 
{ 
    // See https://www.geeksforgeeks.org/orientation-3-ordered-points/ 
    // for details of below formula. 
    float val = (q.y - p.y) * (r.x - q.x) - 
            (q.x - p.x) * (r.y - q.y); 
  
    if (val == 0) return 0; // collinear 
  
    return (val > 0)? 1: 2; // clock or counterclock wise 
} 
  
// The main function that returns true if line segment 'p1q1' 
// and 'p2q2' intersect. 
static boolean doIntersect(PVector p1, PVector q1, PVector p2, PVector q2) 
{ 
    // Find the four orientations needed for general and 
    // special cases 
    float o1 = orientation(p1, q1, p2); 
    float o2 = orientation(p1, q1, q2); 
    float o3 = orientation(p2, q2, p1); 
    float o4 = orientation(p2, q2, q1); 
  
    // General case 
    if (o1 != o2 && o3 != o4) 
        return true; 
  
    // Special Cases 
    // p1, q1 and p2 are collinear and p2 lies on segment p1q1 
    if (o1 == 0 && onSegment(p1, p2, q1)) return true; 
  
    // p1, q1 and q2 are collinear and q2 lies on segment p1q1 
    if (o2 == 0 && onSegment(p1, q2, q1)) return true; 
  
    // p2, q2 and p1 are collinear and p1 lies on segment p2q2 
    if (o3 == 0 && onSegment(p2, p1, q2)) return true; 
  
    // p2, q2 and q1 are collinear and q1 lies on segment p2q2 
    if (o4 == 0 && onSegment(p2, q1, q2)) return true; 
  
    return false; // Doesn't fall in any of the above cases 
} 
