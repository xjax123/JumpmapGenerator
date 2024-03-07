import java.util.concurrent.*;

public class UImanager {
    private List<UIBody> components = new CopyOnWriteArrayList();

    public void render() {
        for (UIBody body : components) {
            body.render();
        }
    }

    public void render(PGraphics buffer) {
        for (UIBody body : components) {
            body.render(buffer);
        }
    }
    public void register(UIBody body) {
        components.add(body);
    }

    public void registerClick(float x, float y) {
        for (UIBody ui : components) {
            if (ui.inBounds(x,y)) {
                ui.onClick(x,y);
            }
        }
    }
    public void registerHold(float x, float y) {
        for (UIBody ui : components) {
            ui.onHold(x,y);
        }
    }
        public void registerRelease(float x, float y) {
        for (UIBody ui : components) {
            ui.onRelease(x,y);
        }
    }
}

public class Touchbox {
    public PVector pos;
    public PVector limit;
    private PVector difference;

    public Touchbox() {
        pos = new PVector(0,0);
        limit = new PVector(0,0);
        difference = new PVector(0,0);
    }
    public Touchbox(PVector pos, PVector limit) {
        this.pos = pos;
        this.limit = limit;
        difference = new PVector(limit.x-pos.x, limit.y-pos.y);
    }

    public void move(PVector newpos) {
        pos = newpos;
        limit = new PVector(newpos.x+difference.x,newpos.y+limit.y);
    }

    public boolean touched(float x, float y) {
        if (x >= pos.x && x <= limit.x && y >= pos.y && y <= limit.y) {
            return true;
        }
        return false;
    }

    @Override
    public String toString() {
        return "[Pos:[x:"+pos.x+",y:"+pos.y+"], Limit:[x:"+limit.x+",y:"+limit.y+"], Difference: [x:"+difference.x+" y:"+difference.y+"]]";
    }
}

public abstract class UIBody implements Renderable{
    protected PVector pos;
    protected PShape design;
    protected Touchbox touch;
    protected boolean enabled = true;
    protected boolean visible = true;
    protected boolean held = false;


    public UIBody(PVector pos, PShape design, Touchbox touch) {
        this.pos = pos;
        this.design = design;
        this.touch = touch;
    }
    //getters
    public PVector pos() {return pos;}
    public int posX() {return (int) pos.x;}
    public int posY() {return (int) pos.y;}
    public boolean getVisibility() {return visible;}
    public boolean getEnabled() {return enabled;}
    public boolean inBounds(float x, float y) {return touch.touched(x,y) && enabled && visible;}

    //setters
    public void setVisibility(boolean b) {visible = b;}
    public void setEnabled(boolean b) {enabled = b;}
    
    public abstract void onClick(float x, float y);
    public abstract void onHold(float x, float y);
    public abstract void onRelease(float x, float y);
    public void render() {
        if (visible) {
            shape(design, pos.x,pos.y);
        }
    }
    public void render(PGraphics buffer) {
        if (visible) {
            buffer.shape(design, pos.x,pos.y);
        }
    }
    @Override
    public String toString() {
      return "[ x:"+pos.x+"y:"+pos.y+" Touchbox:"+touch.toString()+"]";
    }
}

public abstract class UIButton extends UIBody {
    protected String text;
    protected PVector textpos;
    protected color textFill;
    protected float textSize;
    public UIButton(PVector pos, PShape design, float width, float height, String text, color textFill, float textSize, PVector textpos) {
        super(pos,design,new Touchbox(pos, new PVector(pos.x+width,pos.y+height)));
        this.text = text;
        this.textpos = textpos;
        this.textFill = textFill;
        this.textSize = textSize;
    }

    @Override
    public void render() {
        if (visible) {
            shape(design, pos.x,pos.y);
            fill(textFill);
            textSize(textSize);
            text(text,pos.x+textpos.x,pos.y+textpos.y);
        }
    }
    @Override
    public void render(PGraphics buffer) {
        if (visible) {
            buffer.shape(design, pos.x,pos.y);
            buffer.fill(textFill);
            buffer.textSize(textSize);
            buffer.text(text,pos.x+textpos.x,pos.y+textpos.y);
        }
    }
}

public class UIVertSlider extends UIBody {
    PVector trackPos1;
    PVector trackPos2;
    float trackThickness;
    float offsetx;
    float offsety;
    color trackColor;
    float minVal;
    float maxVal;
    float val;
    public UIVertSlider(float sliderWidth, float sliderwHeight,color sliderColor, PVector trackPos1, PVector trackPos2, color trackColor, float trackThickness, float minVal, float maxVal, float startingVal) {
        super(new PVector(0,0),createShape(GROUP),new Touchbox());
        PVector difference = vecSub(trackPos1,trackPos2);
        float norm = normalize(startingVal,minVal,maxVal);
        difference = vecScalarMulti(difference,norm*-1);
        PShape slide = createShape(RECT,0,0,sliderWidth,sliderwHeight);
        slide.setFill(sliderColor);
        slide.setStroke(false);
        this.design = slide;
        this.pos = vecAdd(trackPos1,vecSub(difference,new PVector(sliderWidth*0.5,0)));
        this.touch = new Touchbox(new PVector(pos.x-sliderWidth*0.5,pos.y-sliderwHeight*0.5),new PVector(pos.x+sliderWidth*0.5,pos.y+sliderwHeight*0.5));
        this.trackPos1 = trackPos1;
        this.trackPos2 = trackPos2;
        this.trackThickness = trackThickness;
        this.trackColor = trackColor;
        this.minVal = minVal;
        this.maxVal = maxVal;
        this.val = startingVal;
        this.offsetx = sliderWidth*0.5;
        this.offsety = sliderwHeight*0.5;
    }

    public float getMinVal() {
        return minVal;
    }
    public float getMaxVal() {
        return maxVal;
    }
    public float getVal() {
        return val;
    }

    @Override
    public void render(PGraphics buffer) {
        if (visible) {
            buffer.stroke(trackColor);
            buffer.strokeWeight(trackThickness);
            buffer.line(trackPos1.x,trackPos1.y,trackPos2.x,trackPos2.y);
            buffer.textSize(12);
            buffer.text(Math.round(val),910,20);
            buffer.shape(design, pos.x,pos.y);
        }
    }

    public void onClick(float x, float y) {
            held = true;
        }
    public void onHold(float x, float y) {
        if (held) {
            PVector difference = vecSub(trackPos1,trackPos2);
            float norm = normalize(y,trackPos2.y,trackPos1.y);
            this.val = max(minVal,min(maxVal,((maxVal-minVal)*norm)+minVal));
            this.pos = new PVector(trackPos1.x-offsetx,max(trackPos1.y,min(trackPos2.y,y))-offsety);
            this.touch.move(pos);
        }
    }
    public void onRelease(float x, float y) {
        held = false;
    }
}

public class DeleteButton extends UIButton {
    public DeleteButton(PVector pos, PShape design, float height, float width, color textFill, float textSize, PVector textpos) {
        super(pos,design,height,width,"Delete",textFill,textSize,textpos);
    }
    public void onClick(float x, float y) {
        mode = editMode.DELETE;
        selected = null;
        selectedConn = null;
        selectedStar = null;
    }
    public void onHold(float x, float y) {}
    public void onRelease(float x, float y) {}
}
public class SelectButton extends UIButton {
    public SelectButton(PVector pos, PShape design, float height, float width, color textFill, float textSize, PVector textpos) {
        super(pos,design,height,width,"Select",textFill,textSize,textpos);
    }
    public void onClick(float x, float y) {
        mode = editMode.SELECT;
        selected = null;
        selectedConn = null;
        selectedStar = null;
    }
    public void onHold(float x, float y) {}
    public void onRelease(float x, float y) {}
}
public class AddButton extends UIButton {
    public AddButton(PVector pos, PShape design, float height, float width, color textFill, float textSize, PVector textpos) {
        super(pos,design,height,width,"Add",textFill,textSize,textpos);
    }
    public void onClick(float x, float y) {
        mode = editMode.ADD;
        selected = null;
        selectedConn = null;
        selectedStar = null;
    }
    public void onHold(float x, float y) {}
    public void onRelease(float x, float y) {}
}
public class ClearButton extends UIButton {
    public ClearButton(PVector pos, PShape design, float height, float width, color textFill, float textSize, PVector textpos) {
        super(pos,design,height,width,"Clear",textFill,textSize,textpos);
    }
    public void onClick(float x, float y) {
        selected = null;
        selectedConn = null;
        selectedStar = null;
        starmap.clear();
    }
    public void onHold(float x, float y) {}
    public void onRelease(float x, float y) {}
}
public class GenButton extends UIButton {
    public GenButton(PVector pos, PShape design, float height, float width, color textFill, float textSize, PVector textpos) {
        super(pos,design,height,width,"Generate",textFill,textSize,textpos);
    }
    public void onClick(float x, float y) {
        selected = null;
        selectedConn = null;
        selectedStar = null;
        starmap.clear();
        jmDraw.execute(() -> {prepareJumpmap();});
    }
    public void onHold(float x, float y) {}
    public void onRelease(float x, float y) {}
}