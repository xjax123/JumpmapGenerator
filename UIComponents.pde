public class UImanager {
    private List<UIBody> components;

    public void render() {

    }

    public registerClick(float x, float y) {
        for (UIBody ui : components) {
            if (ui.inBounds(x,y)) {
                ui.onClick();
            }
        }
    }
}

public class Touchbox {
    public PVector pos;
    public PVector limit;
    private PVector difference;

    public Touchbox(PVector pos, PVector limit) {
        this.pos = pos;
        this.limit = limit;
        difference = limit-pos;
    }

    public void move(PVector newpos) {
        pos = newpos;
        limit = newpos+difference;
    }

    public boolean touched(float x, float y) {
        if (x>pos.x && x<limit.x && y>pos.y && y<pos.y) {
            return true;
        }
        return false;
    }
}

public class UIBody {
    private PVector pos;
    private PShape design;
    private Touchbox touch;
    private Runnable click;
    private Runnable hold;
    private Runnable release;


    public UIBody(PVector pos, PShape design, Touchbox touch) {
        this.pos = pos;
        this.design = design;
        this.touch = touch;
    }
    public UIBody(PVector pos, PShape design, Touchbox touch, Runnable click, Runnable hold, Runnable release) {
        this.pos = pos;
        this.design = design;
        this.touch = touch;
        this.click = click;
        this.hold = hold;
        this.release = release;
    }

    public void onClick() {

    }
    public void onHold() {

    }
    public void onRelease() {

    }
    public boolean inBounds(float x, float y) {
        touch.touched(x,y);
    }

    public void render() {

    }
    public void render(PGraphics buffer) {
        
    }
}