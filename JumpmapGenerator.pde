import java.util.*;
import java.util.concurrent.*;

PGraphics screenshot, selectLayer, jumpmap, ui, background;
PImage userBackground;
Thread bgDraw,uiDraw;
ExecutorService jmDraw = Executors.newCachedThreadPool();
StarMap starmap;
UImanager uim = new UImanager();
boolean stateChanged = false;
boolean jumpMapPrepared = false;
boolean uiPrepared = false;
boolean mouseHold = false;
boolean fileSelected = false;
String lastKey = "z";

enum editMode {
    SELECT,
    DELETE,
    ADD
}

enum editType {
    STAR,
    CONNECTION
}

editMode mode = editMode.SELECT;
editType type = editType.STAR;
UStar selectedStar;
Connection selectedConn;
UIVertSlider sizeSlider;
Renderable selected;

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
float jumplaneThickness = 3; //how thick (visiaully) each jumplane is

void setup() {
    size(1000, 1000);
    background(0);
    frameRate(24);
    starmap = new StarMap();
    screenshot = createGraphics(900,900);
    background = createGraphics(1000, 1000);
    selectLayer = createGraphics(900,900);
    jumpmap = createGraphics(900, 900);
    ui = createGraphics(1000, 1000);
    bgDraw = new Thread(() -> {prepareBackground();});
    jmDraw.execute(() -> {prepareJumpmap();});
    uiDraw = new Thread(() -> {prepareUI();});
    bgDraw.start();
    uiDraw.start();
    selectImage();
}

void draw() {
    background(0);
    renderChanges();
    connectionAdd();
    if (fileSelected) {
        image(userBackground,0,0);
    }
    image(background, 0, 0);
    image(selectLayer, 0, 0);
    image(jumpmap, 0, 0);
    image(ui, 0, 0);
}

void selectImage() {
  selectInput("Select a Background:", "fileSelected");
}
void fileSelected(File selection) {
  if (selection != null) {
    userBackground = loadImage(selection.getAbsolutePath());
    userBackground.resize(900,900);
    fileSelected = true;
  }
}

void prepareUI() {
    PShape button = createShape(GROUP);
    PShape base = createShape(RECT, 0,0,150,55);
    base.setFill(color(100,100,100));
    base.setStroke(false);
    PShape base2 = createShape(RECT, 5,5,140,45);
    base2.setFill(color(150,150,150));
    base2.setStroke(color(255,0,0));
    button.addChild(base);
    button.addChild(base2);
    PShape button2 = createShape(GROUP);
    PShape base3 = createShape(RECT, 0,0,210,55);
    base3.setFill(color(100,100,100));
    base3.setStroke(false);
    PShape base4 = createShape(RECT, 5,5,200,45);
    base4.setFill(color(150,150,150));
    base4.setStroke(color(255,0,0));
    button2.addChild(base3);
    button2.addChild(base4);
    uim.register(new SelectButton(new PVector(10,910),button,150,55,color(0),50,new PVector(10,45)));
    uim.register(new AddButton(new PVector(170,910),button,150,55,color(0),50,new PVector(35,45)));
    uim.register(new DeleteButton(new PVector(330,910),button,150,55,color(0),50,new PVector(10,45)));
    uim.register(new ClearButton(new PVector(600,910),button,150,55,color(0),50,new PVector(10,45)));
    uim.register(new GenButton(new PVector(760,910),button2,210,55,color(0),50,new PVector(10,45)));
    UIVertSlider vert = new UIVertSlider(40,20,color(100,100,100),new PVector(950,20),new PVector(950,500),color(100,100,100),4,0,20,8);
    uim.register(vert);
    sizeSlider = vert;

    println("UI Prepared!");
    uiPrepared = true;
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
                    int greenOff = (int) Math.round(Math.random() * (155 - 5) + 5);
                    int blueOff = (int) Math.round(Math.random() * (155 - 5) + 5);
                    color col = color(100,100+greenOff,100+blueOff);
                    int size = (int) Math.round(Math.random() * (starMax - starMin) + starMin);
                    fill(col);
                    noStroke();
                    PShape s = createShape(ELLIPSE,0,0,size,size);
                    PVector pos = new PVector(x,y);
                    UStar star = new UStar(pos,s,size);
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
    for (Connection c : conn) {
        for (Connection cd : conn) {
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
    jumpmap.endDraw();
    jumpMapPrepared = true;
    println("Jumpmap Prepared!");
}
void connectionAdd() {
    if (mode == editMode.ADD && type == editType.CONNECTION) {
        if (selectedStar != null) {
            ui.beginDraw();
            ui.stroke(255,255,255,150);
            ui.strokeWeight(Math.round(sizeSlider.getVal()));
            ui.line(selectedStar.posX(),selectedStar.posY(),mouseX,mouseY);
            ui.endDraw();
        }
    }
}
void prepareBackground() {
    background.beginDraw();
    background.noStroke();
    background.fill(200);
    background.rect(0, 900, 1000, 100);
    background.rect(900, 0, 100, 1000);
    background.endDraw();

    println("Background Prepared!");
}

void renderChanges() {
    if (jumpMapPrepared) {
        jumpmap.beginDraw();
        jumpmap.background(0,0,0,0);
        starmap.render(jumpmap);
        jumpmap.endDraw();
    }
    if (uiPrepared) {
        ui.beginDraw();
        ui.background(0,0,0,0);
        uim.render(ui);
        ui.endDraw();
    }
    if (selected != null) {
        selectLayer.beginDraw();
        selectLayer.background(0,0,0,0);
        selected.render(selectLayer);
        selectLayer.filter(BLUR,8);
        selectLayer.endDraw();
    }
}

void mousePressed() {
    uim.registerClick(mouseX,mouseY);
    starmap.registerClick(mouseX,mouseY,jumplaneThickness);
    if (mode == editMode.ADD && (mouseButton == LEFT)) {
        int greenOff = (int) Math.round(Math.random() * (155 - 5) + 5);
        int blueOff = (int) Math.round(Math.random() * (155 - 5) + 5);
        color col = color(100,100+greenOff,100+blueOff);
        float size = Math.round(sizeSlider.getVal());
        PShape s = createShape(ELLIPSE,0,0,size,size);
        s.setFill(col);
        s.setStroke(false);
        starmap.add(new UStar(new PVector(mouseX,mouseY),s,size));
    } else {

    }
    mouseHold = true;
}

void mouseReleased() {
    uim.registerRelease(mouseX,mouseY);
    starmap.registerRelease(mouseX,mouseY);
    mouseHold = false;
}

void keyPressed() {
    if (key == CODED) {
        if (keyCode == SHIFT) {
            lastKey = "Shift";
        }
    }
    if (key == 27) {
        key = 0;
        selectedConn = null;
        selectedStar = null;
    }
    if (key == 's') {
        lastKey = "s";
        jumpmap.save("Jumpmap-Transparent.png");
    }
    if (lastKey.equals("Shift") || lastKey.equals("s")) {
        if (key == 's' || keyCode == SHIFT) {
            screenshot.beginDraw();
            if (fileSelected) {
                screenshot.image(userBackground,0,0);
            } else {
                background(0);
            }
            screenshot.image(jumpmap,0,0);
            screenshot.endDraw();
            screenshot.save("Jumpmap-Full.png");
        }
    }
}
void mouseDragged(){
    uim.registerHold(mouseX,mouseY);
    starmap.registerHold(mouseX,mouseY);
}