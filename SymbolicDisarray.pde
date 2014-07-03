import processing.serial.*;

Serial myPort;    // Create object from Serial class
Plotter plotter;  // Create a plotter object
int val;          // Data received from the serial port
int lf = 10;      // ASCII linefeed

//Enable plotting?
final boolean PLOTTING_ENABLED = true;

//Plotter dimensions
int xMin = 170;
int yMin = 602;
int xMax = 15370;
int yMax = 10602;

//Current rows and cols
int row = 0;
int col = 0;


//Let's set this up
void setup(){
  background(233, 233, 220);
  size(1537, 1060);
  smooth();
  
  //Select a serial port
  println(Serial.list()); //Print all serial ports to the console
  String portName = Serial.list()[4]; //make sure you pick the right one
  println("Plotting to port: " + portName);
  
  //Open the port
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil(lf);
  
  //Associate with a plotter object
  plotter = new Plotter(myPort);
  
  //Initialize plotter
  plotter.write("IN;SP1;");
  
  //Wait 5 seconds while initializing
  if (PLOTTING_ENABLED) {
    delay(5000);
  }
  
  //Draw a label first (this is pretty cool to watch)
  float ty = map(80, 0, height, yMin, yMax);
  plotter.write("PU"+xMax+","+ty+";"); //Position pen
  plotter.write("SI0.14,0.14;DI0,1;LBSYMBOLIC DISARRAY"+char(3)); //Draw label
    
}

void draw(){
  /* This could have been done in a more elegant way with a nested loop
     but then we wouldn't have gotten live updating on screen while plotting */
  
  /* Draw a grid of predefined symbols */
  int cols = 12; //Total cols. Current column is stored in 'col'
  int rows = 22; //Total rows. Current row is stored in 'row'
  
  if (row < rows && col < cols){
    drawSymbol(col, row);  //only draw if within bounds
    
    //increment for next iteration
    if (col < cols){
      row ++;
      if (row >= rows){
        col++;
        row = 0;
      }
    }
  }
}

void drawSymbol(int c, int r){
  float phi = 0;      //initial rotation
  
  float startX = 100; //offset
  float startY = 100;
  float spaceH = 60;  //spacing
  float spaceW = 60;
  
  Symbol s = new Symbol(100, 100*phi, 100, 100, -15);  

  //Make sure the first row is straight, then randomize
  if (r>2){
    phi = random(-r,r);
  }
   
  s = new Symbol(startX+spaceW*r+phi, startY+spaceH*c+phi, 60, 60, phi);
  s.drawIt();
}



/*************************
  Symbol class
*************************/

class Symbol{
  float tx, ty;
  float w, h;
  float r;
  
  ArrayList<PVector> points = new ArrayList<PVector>();
  
  Symbol(float xpos, float ypos, float scaleX, float scaleY, float rot){
    tx  = xpos;
    ty  = ypos;
    w = scaleX; //scale
    h = scaleY;
    r = radians(rot);
    
    //here's a cube, but you can make any contiguous symbol with this simple coordinate system
    points.add( new PVector(1,0) );
    points.add( new PVector(1,1) );
    points.add( new PVector(0,1) );
    points.add( new PVector(0,0) );
    points.add( new PVector(1,0) );
    
    /*
    //here's an example of a triangle symbol
    points.add( new PVector(0,0) );
    points.add( new PVector(1,1) );
    points.add( new PVector(1,0) );
    points.add( new PVector(0,0) );
    
    //and here's a chevron
    points.add( new PVector(0,0) );
    points.add( new PVector(0.5,0.5) );
    points.add( new PVector(0,1) );
    points.add( new PVector(1,1) );
    points.add( new PVector(1.5,0.5) );
    points.add( new PVector(1,0) );
    points.add( new PVector(0,0) );
    */
  }
  
  void drawIt(){  
    //draw shape  
    for (int i=0; i<points.size()-1; i++){
      drawLine(
        rotX(points.get(i).x, 
        points.get(i).y)*w+tx, 
        rotY(points.get(i).x, 
        points.get(i).y)*h+ty, 
        rotX(points.get(i+1).x, 
        points.get(i+1).y)*w+tx, 
        rotY(points.get(i+1).x, 
        points.get(i+1).y)*h+ty, 
        (i==0)
      );
      
      if (i==points.size()-2){
        plotter.write("PU;");  
      }
    }

    if (PLOTTING_ENABLED){
      delay(250);
    }
  }
  
  void drawLine(float x1, float y1, float x2, float y2, boolean up){
    line(x1, y1, x2, y2);
    float _x1 = map(x1, 0, width, xMin, xMax);
    float _y1 = map(y1, 0, height, yMin, yMax);
    
    float _x2 = map(x2, 0, width, xMin, xMax);
    float _y2 = map(y2, 0, height, yMin, yMax);
    
    String pen = "PD";
    if (up) {pen="PU";}
    
    plotter.write(pen+_x1+","+_y1+";");
    plotter.write("PD"+_x2+","+_y2+";", 75); //75 ms delay
  }
  
  float rotX(float inX, float inY){
   return (inX*cos(r) - inY*sin(r)); 
  }
  
  float rotY(float inX, float inY){
   return (inX*sin(r) + inY*cos(r)); 
  }
}



/*************************
  Simple plotter class
*************************/

class Plotter {
  Serial port;
  
  Plotter(Serial _port){
    port = _port;
  }
  
  void write(String hpgl){
    if (PLOTTING_ENABLED){
      port.write(hpgl);
    }
  }
  
  void write(String hpgl, int del){
    if (PLOTTING_ENABLED){
      port.write(hpgl);
      delay(del);
    }
  }
}
