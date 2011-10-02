import controlP5.*;
import processing.net.*;
import com.sun.jna.win32.*;
import com.sun.jna.ptr.*;
import com.sun.jna.*;
import java.io.*;
import java.util.*;

public static final int PROCESS_QUERY_INFORMATION = 0x0400;
public static final int PROCESS_VM_READ = 0x0010;
public static Pointer PROCESS;
public static int PID;

PImage map_image;
int currentTime;
float timer;
float x_pos = 0;
float y_pos = 0;
float next_x = 0;
float next_y = 0;
float last_x = 0;
float last_y = 0;
int update_interval = 500;
float scaleXY = 1;
int translateX = 0;
int translateY = 0;

NetServer server;
NetClient client;

ControlP5 gui;
Toggle server_toggle;
Toggle trail_toggle;

Textfield ipField;
Textfield nameField;
Textfield portField;
Button connectButton;

PGraphics trailCanvas;

void setup() {
  size( 1024, 768 );
  frameRate(30);
  currentTime = millis();
  timer = 0;
  map_image = loadImage("jc2map.bmp");
  find_process_by_name( "JustCause2.exe" );

  Player.setup( this );
  client = new NetClient( this );
  server = new NetServer( this );

  gui = new ControlP5(this);
  server_toggle = gui.addToggle("server_toggle", true, 10, 10, 100, 20);
  server_toggle.setMode(gui.SWITCH);
  server_toggle.setLabel("client / server");
  trail_toggle = gui.addToggle("trails", false, 10, 45, 40, 20);
  ipField = gui.addTextfield("ipField", 115, 10, 200, 20);
  ipField.setFocus(true);
  ipField.setLabel("IP Address");
  ipField.setText("127.0.0.1");
  portField = gui.addTextfield("Port", 115, 45, 200, 20);
  portField.setText("5204");
  nameField = gui.addTextfield("Name", 115, 80, 200, 20);
  nameField.setText("Someguy");

  connectButton = gui.addButton("connectButton", 0, 325, 10, 100, 20);
  connectButton.setLabel("Connect");

  trailCanvas = createGraphics(2048, 2048, P2D);

  addMouseWheelListener(new java.awt.event.MouseWheelListener() { 
    public void mouseWheelMoved(java.awt.event.MouseWheelEvent evt) { 
      mouseWheel(evt.getWheelRotation());
    }
  }
  ); 

  local_player = new Player("127.0.0.1", -1);
}

void stop() {
  if (client.isOn) {
    client.stop();
  }
}

void update_dt() {
  int dt = millis() - currentTime;
  currentTime = millis();
  update( dt );
}

void update( int dt ) {
  timer += dt;
  x_pos = lerp( last_x, next_x, timer / update_interval );
  y_pos = lerp( last_y, next_y, timer / update_interval );
  if (timer >= update_interval) {
    timer = 0;
    last_x = x_pos;
    last_y = y_pos;
    //next_x = getXPos();
    //next_y = getYPos();
    next_x = random(width);
    next_y = random(height);

    sendPosition( next_x, next_y );
    if (local_player != null && isServer) {
      local_player.setPosition( int(next_x), int(next_y) );
    }
  }

  server.update(dt);
  client.update(dt);
  update_players(dt);
}

void draw() {
  update_dt();
  if ( trail_toggle.getState() ) {
    draw_trails();
  }

  background( 0 );
  pushMatrix();
  translate(width/2 + scaleXY*translateX, height/2 + scaleXY*translateY);
  scale(scaleXY);
  imageMode(CENTER);
  image( map_image, 0, 0 );
  
  if ( trail_toggle.getState() ) {
    imageMode(CORNER);
    image( trailCanvas, 0, 0 );
  }
  
  draw_players();
  popMatrix();
}

void draw_trails() {
  trailCanvas.beginDraw();
  draw_players_trails( trailCanvas );
  trailCanvas.endDraw();
}

void mouseDragged() {
  if (mouseButton == LEFT) {
    translateX += mouseX - pmouseX;
    translateY += mouseY - pmouseY;
  }
}

void mouseWheel(int delta) {
  if (delta == -1) { 
    scaleXY *= 1.25;
  }
  else if ((delta == 1) && (scaleXY > 0.5)) { 
    scaleXY *= 1/1.25;
  }
}

void find_process_by_name( String process_name )
{
  try {
    // Execute command
    String line;
    Process p = Runtime.getRuntime().exec
      (System.getenv("windir") +"\\system32\\"+"tasklist.exe");
    BufferedReader input =
      new BufferedReader(new InputStreamReader(p.getInputStream()));
    while ( (line = input.readLine ()) != null) {
      String[] m = match( line, process_name + "\\s+([0-9]+)" );
      if (m != null ) {
        System.out.println( m[1] );
        PID = int(m[1]);
        setup_processmem();
        break;
      }
    }
    input.close();
  } 
  catch(IOException e) {
    e.printStackTrace();
  }
}

void setup_processmem() 
{
  Kernel32 lib = Kernel32.INSTANCE;
  int bufferSize = 8;
  int offset = 0x011FA2EC;
  PROCESS = lib.OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, PID);
  if (PROCESS == null) {
    throw new RuntimeException("no such pid: " + PID);
  }

  IntByReference baseAddress = new IntByReference( offset );
  Memory outputBuffer = new Memory(bufferSize);

  boolean success = lib.ReadProcessMemory(PROCESS, offset, outputBuffer, bufferSize, null);
  System.out.println("success = " + success);
  byte[] bufferBytes = outputBuffer.getByteArray(0, bufferSize);

  last_x = getXPos();
  last_y = getYPos();
  next_x = last_x;
  next_y = last_y;
}

private interface Kernel32 extends StdCallLibrary
{
  Kernel32 INSTANCE = (Kernel32) Native.loadLibrary("kernel32", Kernel32.class);
  public Pointer OpenProcess(int dwDesiredAccess, boolean bInheritHandle, int dwProcessId);
  boolean ReadProcessMemory(Pointer hProcess, int inBaseAddress, 
  Pointer outputBuffer, int nSize, IntByReference outNumberOfBytesRead);
}

private static float byteArrayToFloat(byte test[]) {
  int MASK = 0xff;
  int bits = 0;
  int i = 3;
  for (int shifter = 3; shifter >= 0; shifter--) {
    bits |= ((int) test[i] & MASK) << (shifter * 8);
    i--;
  }
  return Float.intBitsToFloat(bits);
}

private static float readJC2Address( int offset ) {
  int bufferSize = 8;
  Kernel32 lib = Kernel32.INSTANCE;
  Memory outputBuffer = new Memory(bufferSize);
  boolean success = lib.ReadProcessMemory(PROCESS, offset, outputBuffer, bufferSize, null);
  byte[] bufferBytes = outputBuffer.getByteArray(0, bufferSize);
  return byteArrayToFloat(bufferBytes);
}

public static float getXPos() {
  float x = readJC2Address( (int)0x011FA2E4 );
  return (x + 16384) / 16;
}

public static float getYPos() {
  float y = readJC2Address( (int)0x011FA2EC );
  return (y + 16384) / 16;
}

public static float getZPos() {
  float z = readJC2Address( (int)0x011FA2E8 );
  return z - 200;
}

void server_toggle(boolean theFlag) {
  if (theFlag==true) {
    connectButton.setVisible( true );
    ipField.setVisible( true );
    nameField.setVisible( true );
    portField.setVisible( true );
    server.stop();
    client.stop();
    isServer = false;
  } 
  else {
    connectButton.setVisible( false );
    ipField.setVisible( false );
    nameField.setVisible( false );
    portField.setVisible( false );
    isServer = true;
    client.stop();
    server.start();
    connect();
  }
}


public void connectButton(int theValue) { 
  if (!isServer) { 
    connect();
  }
}

