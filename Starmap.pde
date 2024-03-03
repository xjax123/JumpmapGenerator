class UStar {
    PVector pos;
    int radius;
    color col;
    List<UStar> neighbors;
    
    public UStar(int x, int y, int r, color col) {
        this.pos = new PVector(x,y);
        this.radius = r;
        this.col = col;
        neighbors = new ArrayList<UStar>();
    }
    public UStar() {
        this.pos = new PVector(0,0);
        this.radius = 0;
        this.col = color(0,0,0);
        neighbors = new ArrayList<UStar>();
    }

    public PVector pos() {
        return pos;
    }

    public int posX() {
        return (int) pos.x;
    }

    public int posY() {
        return (int) pos.y;
    }

    public int radius() {
        return radius;
    }

    public color col() {
        return col;
    }
    
    @Override
    public String toString() {
      return "[ x:"+pos.x+"y:"+pos.y+" rad:"+radius+"]";
    }
}

class Connection { 
    UStar pos1;
    UStar pos2;
    float dist;
    color col;

    public Connection(UStar p1, UStar p2, color col) {
        this.col = col;
        pos1 = p1;
        pos2 = p2;
        dist = distance(p1.posX(),p2.posX(),p1.posY(),p2.posY());
    }

    public UStar getFirstStar() {
        return pos1;
    } 
    public UStar getSecondStar() {
        return pos2;
    }

    public PVector getPos1() {
        PVector p1 = pos1.pos();
        PVector p2 = pos2.pos();
        float dx = p2.x-p1.x;
        float dy = p2.y-p1.y;
        float tv = abs(dx)+abs(dy);
        float radius = pos1.radius();
        float nx = normalize(dx,0,tv);
        float ny = normalize(dy,0,tv);
        PVector fin = new PVector(p1.x+nx,p1.y+ny);
        return fin;
    }
    public PVector getPos2() {
        PVector p1 = pos2.pos();
        PVector p2 = pos1.pos();
        float dx = p2.x-p1.x;
        float dy = p2.y-p1.y;
        float tv = abs(dx)+abs(dy);
        float radius = pos2.radius();
        float nx = normalize(dx,0,tv);
        float ny = normalize(dy,0,tv);
        PVector fin = new PVector(p1.x+nx,p1.y+ny);
        return fin;
    }
    public color col() {
        return col;
    }
    public float dist(){
        return dist;
    }
    public boolean match(UStar one, UStar two) {
        if (pos1 == one || pos2 == one) {
            if (pos1 == two || pos2 == two) {
                return true;
            }
        }
        return false;
    }
}

class StarMap {
    private List<UStar> starMap;
    private List<Connection> jump;

    public StarMap() {
        starMap = new ArrayList<UStar>();
        jump = new ArrayList<Connection>();
    }
    public StarMap(List<UStar> list) {
        starMap = list;
        jump = new ArrayList<Connection>();
    }
    public StarMap(List<UStar> list, List<Connection> conn) {
        starMap = list;
        jump = conn;
    }

    public UStar nearestNeighbor(int x, int y) {
        float closestDist = 99999999; //arbitrarily high, so its initialized, but always overwritten
        UStar neighbor = new UStar();
        for (int i = 0; i < starMap.size(); i++) {
            UStar ref = starMap.get(i);
            float dist = distance(x,ref.posX(),y,ref.posY());
            if (dist < closestDist) {
                closestDist = dist;
                neighbor = ref;
            }
        }
        return neighbor;
    }

    public List<UStar> nearestNeighbors(UStar star, float ammount, List<UStar> exclusion, float distanceLimit) {
        ArrayList<UStar> neighbor = new ArrayList<UStar>();
        for (int i = 0; i < starMap.size(); i++) {
            UStar ref = starMap.get(i);
            float dist = distance(star.posX(),ref.posX(),star.posY(),ref.posY());
            if (neighbor.size() == 0 && dist < distanceLimit) {
                if (!exclusion.contains(ref) && ref != star) {
                    neighbor.add(ref);
                }
            }
            for (int a = 0; a < neighbor.size(); a++) {
                UStar na = neighbor.get(a);
                float ndist = distance(star.posX(),na.posX(),star.posY(),na.posY());
                if (dist < ndist && dist < distanceLimit) {
                    if (!exclusion.contains(ref) && ref != star) {
                        if (neighbor.size() < ammount) {
                            neighbor.add(ref); 
                        } else {
                            UStar elim = new UStar();
                            float furDist = 0;
                            for (UStar n : neighbor) {
                                float fdist = distance(star.posX(),n.posX(),star.posY(),n.posY());
                                if (fdist > furDist) {
                                    furDist = fdist;
                                    elim = n;
                                }
                            }
                            neighbor.remove(elim);
                            neighbor.add(ref);
                        }
                    }
                }
            }
        }
        return neighbor;
    }
    public List<UStar> nearestNeighbors(UStar star, float ammount, List<UStar> exclusion) {
        return nearestNeighbors(star,ammount,exclusion,999999999);
    }
    public List<UStar> nearestNeighbors(UStar star, float ammount) {
        return nearestNeighbors(star,ammount,new ArrayList<UStar>());
    }
    public boolean jumpMatch(UStar one, UStar two) {
        for (Connection c : jump) {
            if (c.match(one,two)) {
                return true;
            }
        }
        return false;
    }
    public boolean checkIntersect(Connection one, Connection two) {
        PVector A = one.getPos1();
        PVector B = one.getPos2();
        PVector C = two.getPos1();
        PVector D = two.getPos2();
      return doIntersect(A,B,C,D);
    }

    public void addConnection(UStar one, UStar two) {
        addConnection(one, two, color(255));
    }
    public void addConnection(UStar one, UStar two, color col) {
        if (!jumpMatch(one,two)) {
            jump.add(new Connection(one, two, col));
        }
    }
    public void removeConnection(Connection c) {
        jump.remove(c);
    }

    public List<Connection> getJumpLanes() {
        return jump;
    }

    public void add(UStar star) {
        starMap.add(star);
    }

    public int size() {
        return starMap.size();
    }

    public UStar retrieve(int index) {
        return starMap.get(index);
    }
}
