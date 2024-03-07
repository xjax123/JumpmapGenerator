public float normalize(float val, float min, float max) {
    return (val - min)/(max - min);
}

public float distance(float x1, float x2, float y1, float y2) {
    return (float) Math.sqrt(Math.pow(x2-x1,2)+Math.pow(y2-y1,2));
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

boolean onSegment(PVector p, PVector q, PVector r) 
{ 
    if (q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) && 
        q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y)) 
    return true; 
  
    return false; 
} 
  

float orientation(PVector p, PVector q, PVector r) 
{ 
    float val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y); 
    if (val == 0) return 0;
    return (val > 0)? 1: 2;
} 
   
boolean doIntersect(PVector p1, PVector q1, PVector p2, PVector q2) 
{ 
    float o1 = orientation(p1, q1, p2); 
    float o2 = orientation(p1, q1, q2); 
    float o3 = orientation(p2, q2, p1); 
    float o4 = orientation(p2, q2, q1); 

    if (o1 != o2 && o3 != o4) return true; 
    if (o1 == 0 && onSegment(p1, p2, q1)) return true; 
    if (o2 == 0 && onSegment(p1, q2, q1)) return true; 
    if (o3 == 0 && onSegment(p2, p1, q2)) return true; 
    if (o4 == 0 && onSegment(p2, q1, q2)) return true; 
  
    return false;
} 
  boolean isOnLine(PVector v0, PVector v1, PVector p, float w) {
    // Return minimum distance between line segment vw and point p
    PVector vp = new PVector();
    PVector line = PVector.sub(v1, v0);
    float l2 = line.magSq();  // i.e. |w-v|^2 -  avoid a sqrt
    if (l2 == 0.0) {
      vp.set(v0);
      return false;
    }
    PVector pv0_line = PVector.sub(p, v0);
    float t = pv0_line.dot(line)/l2;
    pv0_line.normalize();
    vp.set(line);
    vp.mult(t);
    vp.add(v0);
    float d = PVector.dist(p, vp);
    if (t >= 0 && t <= 1 && d <= w)
      return true;
    else
      return false;
  }

float vecDot(PVector v1, PVector v2) {
    float x = v1.x*v2.x;
    float y = v1.y*v2.y;
    return x+y;
}
PVector vecAdd(PVector v1, PVector v2) {
    return new PVector(v1.x+v2.x,v1.y+v2.y);
}
PVector vecSub(PVector v1, PVector v2) {
    return new PVector(v1.x-v2.x,v1.y-v2.y);
}
PVector vecMulti(PVector v1, PVector v2) {
    return new PVector(v1.x*v2.x,v1.y*v2.y);
}
PVector vecDiv(PVector v1, PVector v2) {
    return new PVector(v1.x/v2.x,v1.y/v2.y);
}
PVector vecScalarAdd(PVector v, float s) {
    return new PVector(v.x+s,v.y+s);
}
PVector vecScalarSub(PVector v, float s) {
    return new PVector(v.x-s,v.y-s);
}
PVector vecScalarMulti(PVector v, float s) {
    return new PVector(v.x*s,v.y*s);
}
PVector vecScalarDiv(PVector v, float s) {
    return new PVector(v.x/s,v.y/s);
}
PVector vecPow (PVector v, float power) {
    return new PVector((float) Math.pow(v.x,power), (float) Math.pow(v.y,power));
}