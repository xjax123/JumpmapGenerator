class UStar extends UIBody{
    float radius;

    public UStar(PVector pos, PShape design, float radius) {
        super(pos,design,new Touchbox());
        this.radius = radius;
    }
    public UStar() {
        super(new PVector(0,0),createShape(),new Touchbox());
    }

    public float radius() {
        return radius;
    }

    @Override
    public boolean inBounds(float x, float y) {
        float u = distance(x,pos.x,y,pos.y);
        if (u < radius()/2) {return true;}
        return false;
    }  

    public void onClick(float x, float y) {
        held = true;
        if (mode == editMode.DELETE) {
            if (mousePressed && (mouseButton == LEFT)) {
                starmap.removeStar(this);
            }
        } else if (mode == editMode.SELECT) {
            if (mousePressed && (mouseButton == LEFT)) {
                selected = this;
            }
        } else if (mode == editMode.ADD) {
            if (mousePressed && (mouseButton == RIGHT)) {
                if (this != selectedStar && selectedStar != null) {
                    starmap.addConnection(this, selectedStar, color(255),Math.round(sizeSlider.getVal()));
                    selectedStar = null;
                    type = editType.STAR; 
                } else {
                    type = editType.CONNECTION; 
                    selectedStar = this;
                }
            }
        } 
    }
    public void onHold(float x, float y) {
        if (mode == editMode.SELECT && held) {
            if (mousePressed && (mouseButton == LEFT)) {
                this.pos = new PVector(x,y);
            }   
        }
    }
    public void onRelease(float x, float y) {
        held = false;
    }
}

class Connection implements Renderable{ 
    UStar pos1;
    UStar pos2;
    float dist;
    color col;
    float laneThickness;

    public Connection(UStar p1, UStar p2, color col, float laneThickness) {
        this.col = col;
        pos1 = p1;
        pos2 = p2;
        dist = distance(p1.posX(),p2.posX(),p1.posY(),p2.posY());
        this.laneThickness = laneThickness;
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

    public void onClick() {
        if (mode == editMode.DELETE) {
            if (mousePressed && (mouseButton == RIGHT)) {
                starmap.removeConnection(this);
            }
        }
        if (mode == editMode.SELECT) {
            if (mousePressed && (mouseButton == RIGHT)) {
                selected = this;
            }
        }
    }
    public boolean clicked(float x, float y, float w) {
        PVector A = pos1.pos();
        PVector B = pos2.pos();
        return isOnLine(A,B,new PVector(x,y),w);
    }

    public void render(PGraphics buffer) {
        buffer.stroke(col());
        buffer.strokeWeight(laneThickness);
        buffer.line(getPos1().x,getPos1().y,getPos2().x,getPos2().y);
    }
    public void render() {

    }
}

class StarMap {
    private List<UStar> starMap;
    private List<Connection> jump;

    public StarMap() {
        starMap = new CopyOnWriteArrayList<UStar>();
        jump = new CopyOnWriteArrayList<Connection>();
    }
    public StarMap(CopyOnWriteArrayList<UStar> list) {
        starMap = list;
        jump = new CopyOnWriteArrayList<Connection>();
    }
    public StarMap(CopyOnWriteArrayList<UStar> list, CopyOnWriteArrayList<Connection> conn) {
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
        addConnection(one, two, color(255),jumplaneThickness);
    }
    public void addConnection(UStar one, UStar two, color col, float thickness) {
        if (!jumpMatch(one,two)) {
            jump.add(new Connection(one, two, col,thickness));
        }
    }
    public void removeConnection(Connection c) {
        jump.remove(c);
        stateChanged = true;
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

    public void removeStar(UStar s) {
        for (Connection c : jump) {
            if (s == c.getFirstStar() || s == c.getSecondStar()) { 
                removeConnection(c);
            }
        }
        starMap.remove(s);
        stateChanged = true;
    }

    public UStar retrieve(int index) {
        return starMap.get(index);
    }

    public void registerClick(float x, float y, float width) {
        for (UStar ui : starMap) {
            if (ui.inBounds(x,y)) {
                ui.onClick(x,y);
            }
        }
        for (Connection conn : jump) {
            if (conn.clicked(x,y,width+0.5)) {
                conn.onClick();
            }
        }
    }
    public void registerHold(float x, float y) {
        for (UStar ui : starMap) {
            ui.onHold(x,y);
        }
    }
    public void registerRelease(float x, float y) {
        for (UStar ui : starMap) {
            ui.onRelease(x,y);
        }
    }
    public void render(PGraphics buffer) {
        for (Connection c : jump) {
            c.render(buffer);
        }
        for (UStar s : starMap) {
            s.render(buffer);
        }
    }
    public void clear() {
        for (UStar star : starMap) {
            removeStar(star);
        }
    }
}
