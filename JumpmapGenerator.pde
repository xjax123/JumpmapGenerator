import java.util.*;

PGraphics jumpmap, background;
Thread jmDraw,bgDraw;
StarMap starmap;

//Fiddly Bits
//Change these to affect the generated image.
float freq1 = 0.003; //Layer 1 Noise Frequency
float freq2 = 0.01; // Layer 2 Noise Frequency
int minGap = 30; //min number of pixels between each star.
int starMax = 10; //max size of stars
int starMin = 8; //min size of stars
float starWeight = 3; //influences the number of stars generated, higher is more.
float distanceMod = 0.5; //influences how agressive it cuts off lanes because of the distance between stars.
int buffer = 30; //how far away from the sides of the window stars can begin spawning.
int maxJumps = 6; //maximum jump connections a star can have.
float jumpDistance = 80; //how far jumplanes can connect
float jumplaneThickness = 2; //how thick (visiaully) each jumplane is

void setup() {
    size(900, 1000);
    background(0);
    frameRate(8);
    starmap = new StarMap();
    background = createGraphics(900, 1000);
    jumpmap = createGraphics(900, 900);
    bgDraw = new Thread(() -> {prepareBackground();});
    jmDraw = new Thread(() -> {prepareJumpmap();});
    bgDraw.start();
    jmDraw.start();
}

void draw() {
    background(0);
    image(background, 0, 0);
    image(jumpmap, 0, 0);
}
void keyPressed() {
    if (key == 's') {
        jumpmap.save("Jumpmap-Transparent.png");
    }
}

void prepareJumpmap() {
    jumpmap.beginDraw();
    float[] map = new float[jumpmap.width*jumpmap.height];
    float mapmax = 0;
    float mapmin = 1;
    jumpmap.loadPixels();
    for(int y = 0; y < jumpmap.height; y++) {
        //precomputing all y values to help save on render time
        float prey1 = y*freq1;
        float prey2 = y*freq2;
        int backy = y*jumpmap.width;
        for (int x = 0; x < jumpmap.width; x++) {
            //generating base noise values
            float n = noise(x*freq1, prey1,20);
            float d = noise(x*freq2, prey2,30);
            
            //compound value (weighted towards lower detail noise) to give texture
            float comp = n*0.7+d*0.3;
            comp += 1.0;
            comp *= 0.5; //avoiding division

            map[backy+x] = comp; //adding raw values to a map for later reference
            if (comp > mapmax) {
                mapmax = comp;
            }
            if (comp < mapmin) {
                mapmin = comp;
            }
        }
    }
    
    for(int y = 0; y < jumpmap.height; y++) {
        if (y < buffer || y > jumpmap.height-buffer) {
          continue;
        }
        int backy = y*jumpmap.width;
        for (int x = 0; x < jumpmap.width; x++) {        
            if (x < buffer || x > jumpmap.width-buffer) {
              continue;
            }
            //exponential random function so stars are clustered around light points.
            float val = (float) Math.log(Math.random())/((float) -normalize(map[backy+x],mapmin,mapmax)*(starWeight*0.01));
            if (val < 0.1) {
                //testing if the generated star is too close to an existing one (as defined by minGap)
                //this is pretty slow, because it reduces this loop to O(N^3) but other approaches like GLSL compute shaders would be a bit too time intensive for me to work on right now.
                UStar nearest = starmap.nearestNeighbor(x,y);
                float dist = distance(x,nearest.posX(),y,nearest.posY());
                if (dist > minGap) {
                    UStar star;
                    int greenOff = (int) Math.round(Math.random() * (155 - 5) + 5);
                    int blueOff = (int) Math.round(Math.random() * (155 - 5) + 5);
                    color col = color(100,100+greenOff,100+blueOff);
                    int size = (int) Math.round(Math.random() * (starMax - starMin) + starMin);
                    star = new UStar(x,y,size,col);
                    starmap.add(star);
                }
            }
        }
    }

    for (int i = 0; i < starmap.size(); i++) {
        UStar s = starmap.retrieve(i);
        List<UStar> jumpRoutes = starmap.nearestNeighbors(s,maxJumps,new ArrayList<UStar>(),jumpDistance);
        int routes = jumpRoutes.size();
        for (int x = jumpRoutes.size()-1; x > 0; x--) {
            UStar routeStar = jumpRoutes.get(x);
            float dist = distance(s.posX(),routeStar.posX(),s.posY(),routeStar.posY());
            float val = (float) Math.log(Math.random())/((float) normalize(dist,0,jumpDistance)*(distanceMod*0.01));
            if (routes <= 2) {
                break;
            }
            if (val < 0.1) {
                jumpRoutes.remove(routeStar);
                routes--;
            }
        }
        for(UStar star : jumpRoutes) {
            starmap.addConnection(s,star);
        }

    }

    List<Connection> conn = starmap.getJumpLanes();
    List<Connection> newCon = new ArrayList<Connection>();
    for (Connection c : conn) {
        newCon.add(c);
    }
    for (Connection c : newCon) {
        for (Connection cd : newCon) {
            if (cd != c) {
                if (starmap.checkIntersect(c,cd)) {
                    if (c.dist() > cd.dist()) {
                        starmap.removeConnection(c);
                    } else {
                        starmap.removeConnection(cd);
                    }
                }
            }
        }
    }
    conn = starmap.getJumpLanes();
    for (Connection c : conn) {
        jumpmap.fill(c.col());
        jumpmap.stroke(255);
        jumpmap.strokeWeight(jumplaneThickness);
        jumpmap.line(c.getPos1().x,c.getPos1().y,c.getPos2().x,c.getPos2().y);
    }

    for (int i = 0; i < starmap.size();i++) {
        UStar s = starmap.retrieve(i);
        jumpmap.fill(s.col());
        jumpmap.noStroke();
        jumpmap.circle(s.posX(),s.posY(),s.radius);
    }
    jumpmap.endDraw();
}

void prepareBackground() {
    background.beginDraw();
    background.fill(255);
    background.rect(0, 900, 1000, 100);
    background.endDraw();
}
