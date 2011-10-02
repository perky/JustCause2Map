public static class Player {
  
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
      x_pos = lerp(last_x, next_x, timer / time_diff);
      y_pos = lerp(last_y, next_y, timer / time_diff);
    } else if (timer >= time_diff) {
      timer = 0;
      last_x = next_x;
      last_y = next_y;
    }
  }
  
  void draw() {
    parent.fill( 255, 0, 0 );
    parent.ellipse( x_pos, y_pos, 5, 5 );
    parent.text( name, x_pos, y_pos-5 );
  }
  
  void draw_trails(PGraphics canvas){
    canvas.fill( 255, 150, 150 );
    canvas.ellipse( x_pos+1024, y_pos+1024, 3, 3 );
  }
  
  void setPosition(int x, int y) {
    time_diff = parent.millis() - last_update_time;
    last_update_time = parent.millis();
    timer = 0;
    last_x = x_pos;
    last_y = y_pos;
    next_x = x;
    next_y = y;
  }
}
