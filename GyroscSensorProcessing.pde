import processing.video.*;
import oscP5.*;
import netP5.*;
import controlP5.*;

static final int OSC_LISTENING_PORT = 9999;
static final int PITCH = 0;
static final int ROLL = 1;
static final int YAW = 2;
static final int X = 0;
static final int Y = 1;
static final int Z = 2;

ControlP5 cp5;
OscP5 oscP5;

NetAddress phoneAddress;
CheckBox checkbox;

PShader bloom;
PShader blur;
PShader edge;
PShader colorize;
PShader overlay;

PGraphics[] passes = new PGraphics[8];

float[] gyroscope = new float[3];
float[] acceleration = new float[3];
float[] gravity = new float[3];
float heading = 0.0f;

boolean doColorize = false;
boolean doBlur = false;
boolean doBloom = false;
boolean doEdge = false;
boolean doAccelerometer = false;
boolean doGyroscope = false;
boolean doCompass = false;

Movie movie;

void setup() {
  //movie = new Movie(this, "Silhouette Animation - Short Film by Janne Marete Grødum.mp4");
  //movie = new Movie(this, "Animation - Jeremie Fleury _ Silhouette.mp4");
  movie = new Movie(this, "User Tracker.mp4");
  movie.loop();
  
  size(movie.width, movie.height, P2D);
  background(255);

  hint(DISABLE_DEPTH_MASK);
  
  cp5 = new ControlP5(this);
  checkbox = cp5.addCheckBox("checkBox")
                .setPosition(10, 10)
                .setColorForeground(color(120))
                .setColorActive(color(200, 0, 0))
                .setColorLabel(color(200))
                .setSize(10, 10)
                .setItemsPerRow(1)
                .setSpacingColumn(30)
                .setSpacingRow(10)
                .addItem("Colorize", 1)
                .addItem("Edge", 2)
                .addItem("Blur", 3)
                .addItem("Bloom", 4)
                .addItem("Gyro", 5)
                .addItem("Accel", 6)
                .addItem("Compass", 7)
                ;
  
  colorize = loadShader("colorize.glsl");
  blur = loadShader("blur.glsl"); 
  blur.set("blurSize", 20);
  blur.set("sigma", 10.0f);  
  edge = loadShader("edges.glsl");
  bloom = loadShader("bloom.glsl");
  overlay = loadShader("overlay.glsl");

  for (int i=0; i<passes.length; i++) {
    passes[i] = createGraphics(width, height, P2D);
    passes[i].noSmooth();  
  }
  
  oscP5 = new OscP5(this, OSC_LISTENING_PORT);
  phoneAddress = null;
}

  void movieEvent(Movie m) {
    m.read();
  }
  
  void draw() {
    int i = 0;
    int lastPass = 0;
    float sigmaScale = (doAccelerometer) ? abs(1.0 - acceleration[Z]) : 1;
  
    passes[0].beginDraw();
    passes[0].image(movie, 0, 0);
    passes[0].resetShader();
    passes[0].endDraw();
    
    for (i=0; i<passes.length; i++) {
      passes[i].beginDraw();
      if (i == 0 && doColorize) {
        float alpha = (doCompass) ? heading : 0.2;
        colorMode(HSB);
        if (doGyroscope) {
          color c = color( map(gyroscope[0], -PI, PI, 0, 255),
                           map(gyroscope[1], -PI, PI, 0, 255),
                           map(gyroscope[2], -PI, PI, 100, 255));
          colorMode(RGB);
          colorize.set("r", red(c) / 255.0);
          colorize.set("g", green(c) / 255.0);
          colorize.set("b", blue(c) / 255.0);
        }
        
        colorize.set("a", map(alpha, 0.0f, 360.0f, 0.01, 0.3));
        passes[i].shader(colorize);
        passes[i].image(passes[lastPass], 0, 0);
        lastPass = i;
      } else if (i==1 && doEdge) {
        passes[i].shader(edge);  
        passes[i].image(passes[lastPass], 0, 0); 
        lastPass = i;       
      } else if (i == 2 && doBlur) {
        blur.set("horizontalPass", 0);
        blur.set("sigma", 10.0f * sigmaScale); 
        passes[i].shader(blur); 
        passes[i].image(passes[lastPass], 0, 0);
        lastPass = i;
      } else if (i == 3 && doBlur) {
        blur.set("horizontalPass", 1);
        blur.set("sigma", 10.0f * sigmaScale); 
        passes[i].shader(blur); 
        passes[i].image(passes[lastPass], 0, 0);
        lastPass = i;    
      } else if (doBloom) {
        passes[i].shader(bloom);  
        passes[i].image(passes[lastPass], 0, 0);
        lastPass = i;
      }
      passes[i].endDraw();
    }

    //tint(255, 50);
    //image(passes[0], 0, 0);

    float XScale = (doAccelerometer) ? pow(abs(1-acceleration[X]), 2) : 1;
    float YScale = (doAccelerometer) ? pow(abs(1-acceleration[Y]), 2) : 1;

    image(passes[lastPass], -20 * XScale, 
                            -20 * YScale, 
                            width + (20 * XScale), 
                            height + (20 * YScale));
}

void mousePressed() {
}

void parseGyroscope(OscMessage msg) {
  gyroscope[PITCH] = msg.get(PITCH).floatValue(); 
  gyroscope[ROLL] = msg.get(ROLL).floatValue();
  gyroscope[YAW] = msg.get(YAW).floatValue();
  
  println("## Gyro: [" + gyroscope[PITCH] + ", " + gyroscope[ROLL] + ", " + gyroscope[YAW] + "]");
}

void parseAccelerometer(OscMessage msg) {
  acceleration[X] = msg.get(X).floatValue(); 
  acceleration[Y] = msg.get(Y).floatValue();
  acceleration[Z] = msg.get(Z).floatValue();
  
  println("## Accel: [" + acceleration[X] + ", " + acceleration[Y] + ", " + acceleration[Z] + "]");
}

void parseGravity(OscMessage msg) {
  gravity[X] = msg.get(X).floatValue(); 
  gravity[Y] = msg.get(Y).floatValue();
  gravity[Z] = msg.get(Z).floatValue();
  
  println("## Gravity: [" + gravity[X] + ", " + gravity[Y] + ", " + gravity[Z] + "]");
}

void parseCompass(OscMessage msg) {
  heading = msg.get(0).floatValue();
  
  println("## Heading: [" + heading + "]");
}

void parseRotationMatrix(OscMessage msg) {
  
}

void oscEvent(OscMessage msg) {
  /* check if msg has the address pattern we are looking for. */
  
  //println("## GOT: " + msg + ", " + msg.typetag());
  
  if(msg.checkAddrPattern("/gyrosc/skate/ipport") == true && msg.checkTypetag("si") == true) {
    String ip = msg.get(0).stringValue();
    int port = msg.get(1).intValue();
    println("== IPPORT: " + ip + ":" + port);
    
    if (phoneAddress == null) {
      phoneAddress = new NetAddress(ip, port);
      println("SET NETADDR: " + phoneAddress);
      background(255);
    }   
  } else if (msg.checkAddrPattern("/gyrosc/skate/gyro")) {
    parseGyroscope(msg); 
  } else if (msg.checkAddrPattern("/gyrosc/skate/accel")) {
    parseAccelerometer(msg);
  } else if (msg.checkAddrPattern("/gyrosc/skate/comp")) {
    parseCompass(msg); 
  } else if (msg.checkAddrPattern("/gyrosc/skate/grav")) {
    parseGravity(msg); 
  }
  /*
    if(msg.checkTypetag("ifs")) {
      int firstValue = msg.get(0).intValue();  
      float secondValue = msg.get(1).floatValue();
      String thirdValue = msg.get(2).stringValue();
      print("### received an osc message /test with typetag ifs.");
      println(" values: "+firstValue+", "+secondValue+", "+thirdValue);
      return;
    }
  */  
}

void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom(checkbox)) {
    int col = 0;
    for (int i=0;i<checkbox.getArrayValue().length;i++) {
      int n = (int)checkbox.getArrayValue()[i];
      switch (i) {
        case 0:
          doColorize = boolean(n);
          break;
        case 1:
          doEdge = boolean(n);
          break;
        case 2:
          doBlur = boolean(n);
          break;
        case 3:
          doBloom = boolean(n);
          break;
        case 4:
          doGyroscope = boolean(n);
          break;
        case 5:
          doAccelerometer = boolean(n);
          break;
        case 6:
          doCompass = boolean(n);
          break;
        default:
          ;
      }
    }
    println();    
  }
}
