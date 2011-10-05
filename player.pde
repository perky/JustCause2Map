public static class Player {
  PVector pos, last_pos, current_pos;
  float x_pos;
  float y_pos;
  float last_x;
  float last_y;
  float next_x;
  float next_y;
  
  float timer;
  float time_diff;
  int last_update_time;
  public String name = "";
  public String ip;
  public int last_ping;
  public int id;
  
  public static int numberOfPlayers = 0;
  private static PApplet parent;
  public static Map<Integer, Player> instances = new HashMap<Integer, Player>();
  
  static void setup(PApplet theParent) {
    parent = theParent;
  }
  
  public Player(String anIP, int anID){
    ip = anIP;
    current_pos = new PVector(0,0);
    if (anID == -1) {
      id = numberOfPlayers++;
      instances.put( id, this );
    } else {
      id = anID;
      instances.put( id, this );
    }
  }
  
  static Player findByIp(String theIP) {
    Player foundPlayer = null;
    for (int i : instances.keySet()) {
      Player player = instances.get(i);
      if(player.ip.equals(theIP) == true) {
        foundPlayer = player;
        break;
      }
    }
    return foundPlayer;
  }
  
  static Player findByName(String theName) {
    Player foundPlayer = null;
    for (int i : instances.keySet()) {
      Player player = instances.get(i);
      if(player.name.equals(theName) == true) {
        foundPlayer = player;
        break;
      }
    }
    return foundPlayer;
  }
  
  static boolean doesExist(int id) {
    return instances.containsKey(id);
  }
  
  void destroy() {
    instances.remove( id );
  }
  
  void setName(String name) {
    this.name = name;
  }
  
  void update(int dt){
    timer += dt;
    if (timer < time_diff) {
      current_pos = vectorLerp( last_pos, pos, timer / time_diff );
    } else if (timer >= time_diff) {
      timer = 0;
      if (pos != null)
        last_pos = pos.get();
    }
  }
  
  void draw() {
    parent.fill( 255, 0, 0 );
    parent.ellipse( current_pos.x, current_pos.y, 5, 5 );
    parent.text( name, current_pos.x, current_pos.y-5 );
  }
  
  void draw_trails(PGraphics canvas){
    canvas.noStroke();
    canvas.fill( 255, 0, 0, 10 );
    canvas.ellipse( current_pos.x+1024, current_pos.y+1024, 4,4 );
  }
  
  void setPosition(int x, int y) {
    time_diff = parent.millis() - last_update_time;
    last_update_time = parent.millis();
    timer = 0;
    
    if (pos == null) {
      pos = new PVector( float(x), float(y) );
      last_pos = pos.get();
    } else {
      last_pos = pos.get();
      pos = new PVector( float(x), float(y) );
    }
  }
  
  void setPositionInstant(PVector posVec) {
    current_pos = posVec.get();
  }
  
  PVector vectorLerp( PVector vec1, PVector vec2, float amount ) {
    float x = lerp( vec1.x, vec2.x, amount );
    float y = lerp( vec1.y, vec2.y, amount );
    float z = lerp( vec1.z, vec2.z, amount );
    return new PVector( x, y, z );
  }
}
