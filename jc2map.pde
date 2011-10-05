import controlP5.*;
import processing.net.*;
import com.sun.jna.win32.*;
import com.sun.jna.ptr.*;
import com.sun.jna.*;
import java.io.*;
import java.util.*;
import java.lang.Exception;

public static CUser32 User32 = CUser32.INSTANCE;
public static CKernel32 Kernel32 = CKernel32.INSTANCE;
public static int PROCESS_TERMINATE = 1;
public static final int PROCESS_QUERY_INFORMATION = 0x0400;
public static final int PROCESS_VM_READ = 0x0010;
public static int ACCESS_FLAGS = 0x0439;
public static int hProcess;
public static int waypoint_ingame_x_addr = 0x11214174;
public static int waypoint_ingame_y_addr = 0x1121417C;
public static int waypoint_ingame_z_addr = 0x11214178;
public static int PID;

PVector pos, last_pos, rawPos, last_rawPos;

PImage map_image;
int currentTime;
float timer;

int update_interval = 500;
int waypoint_update_interval = 100;
int waypoint_timer;
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
  size( 568, 568 );
  frameRate(30);
  currentTime = millis();
  timer = 0;
  map_image = loadImage("jc2map.bmp");

  setup_processmem();
  rawPos = getPlayerPosition();
  last_rawPos = rawPos.get();
  pos = translatedPlayerPosition( rawPos );
  last_pos = pos.get();

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
  waypoint_timer = millis() + waypoint_update_interval;
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
  
  // Interpolate between last position and current position.
  PVector current_pos = vectorLerp( last_pos, pos, timer / update_interval );
  
  if (local_player != null) {
    local_player.setPositionInstant( current_pos );
  }

  if (timer >= update_interval) {
    timer = 0;

    // Read position from memory.
    last_pos = pos.get();
    last_rawPos = rawPos.get();
    rawPos = getPlayerPosition();
    pos = translatedPlayerPosition( rawPos );

    // Netword position.
    sendPosition( pos );
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
    image( trailCanvas, -1024, -1024 );
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

void mousePressed() {
  if (mouseButton == RIGHT) {
    float x = float( (mouseX - translateX) - (width/2) ) * (32768/2048);
    float y = float( (mouseY - translateY) - (height/2) ) * (32768/2048);
    float z = 400;
    writeWaypointPos( x, y, z );
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

void setup_processmem() {
  int[] dwProcessId = new int[1];
  int hWnd = User32.FindWindowA(null, "Just Cause 2");
  User32.GetWindowThreadProcessId(hWnd, dwProcessId);
  hProcess = Kernel32.OpenProcess(ACCESS_FLAGS, 0, dwProcessId[0]);
}

public interface CUser32 extends Library {
  CUser32 INSTANCE = (CUser32)
    Native.loadLibrary((Platform.isWindows() ? "user32" : null), 
    CUser32.class);

  int FindWindowA(String ClassName, String WindowName);
  int GetWindowThreadProcessId(int hWnd, int[] lpdwProcessId);
}

public interface CKernel32 extends Library {
  CKernel32 INSTANCE = (CKernel32)
    Native.loadLibrary((Platform.isWindows() ? "kernel32" : null), 
    CKernel32.class);

  int OpenProcess(int dwDesiredAccess, int bInheritHandle, int dwProcessId);
  int TerminateProcess(int hProcess, int uExitCode);
  int WriteProcessMemory(int hProcess, int lpBaseAddress, int[] lpBuffer, int nSize, int[] lpNumberOfBytesWritten);
  boolean ReadProcessMemory(int hProcess, int inBaseAddress, 
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

private static float readJC2Address( int address ) {
  int bufferSize = 8;
  Memory outputBuffer = new Memory(bufferSize);
  boolean success = Kernel32.ReadProcessMemory(hProcess, address, outputBuffer, bufferSize, null);
  byte[] bufferBytes = outputBuffer.getByteArray(0, bufferSize);
  return byteArrayToFloat(bufferBytes);
}

private static void writeJC2Address( int address, int[] value ) {
  Kernel32.WriteProcessMemory(hProcess, address, value, 4, null);
}

public static void writeWaypointPos( float x, float y, float z ) {
  try {
    int[] ix = {
      BitConverter.toInt32( BitConverter.getBytes( x ), 0 )
    };
    int[] iy = {
      BitConverter.toInt32( BitConverter.getBytes( y ), 0 )
    };
    int[] iz = {
      BitConverter.toInt32( BitConverter.getBytes( z ), 0 )
    };
    Kernel32.WriteProcessMemory(hProcess, waypoint_ingame_y_addr, iy, 4, null);
    Kernel32.WriteProcessMemory(hProcess, waypoint_ingame_x_addr, ix, 4, null);
    Kernel32.WriteProcessMemory(hProcess, waypoint_ingame_z_addr, iz, 4, null);
  } 
  catch (Exception e) {
    println("nope");
  }
}

PVector getPlayerPosition() {
  float x = readJC2Address( (int)0x011FA2E4 );
  float y = readJC2Address( (int)0x011FA2EC );
  float z = readJC2Address( (int)0x011FA2E8 );
  return new PVector( x, y, z );
}

PVector translatedPlayerPosition( PVector vec ) {
  float ratio = 32768 / 2048;
  float x = vec.x / ratio;
  float y = vec.y / ratio;
  float z = vec.z - 200;
  return new PVector( x, y, z );
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

PVector vectorLerp( PVector vec1, PVector vec2, float amount ) {
  float x = lerp( vec1.x, vec2.x, amount );
  float y = lerp( vec1.y, vec2.y, amount );
  float z = lerp( vec1.z, vec2.z, amount );
  return new PVector( x, y, z );
}

