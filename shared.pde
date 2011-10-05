boolean isServer = false;
boolean hasStarted = true;
boolean isConnected = false;
public static final int MSG_CLIENT_CONNECT     = 0;
public static final int MSG_CLIENT_DISCONNECT  = 1;
public static final int MSG_POSITION_UPDATE    = 2;
public static final int MSG_NAME_UPDATE        = 3;
public static final int MSG_HANDSHAKE          = 4;
public static final int MSG_PING               = 5;
public static final char MSG_END = '*';

public static Player local_player;

void connect() {
  hasStarted = false;
  String name = nameField.getText();
  Player.numberOfPlayers = 0;

  if (isServer) {
    Player.instances.remove(0);
    local_player = new Player("127.0.0.1", -1);
    local_player.name = name;
    isConnected = true;
  } else {
    client.start( ipField.getText(), nameField.getText() );
  }
}

void send_message(String data) {
  if (!isConnected){return;}
  data = data + MSG_END;
  if (isServer) {
    server.server.write(data);
  } else {
    client.client.write(data);
  }
}

void sendPosition(PVector pos) {
  if (local_player != null) {
    int x = int(pos.x);
    int y = int(pos.y);
    String data = MSG_POSITION_UPDATE + "," + local_player.id + "," + x + "," + y;
    send_message( data );
  }
}

void positionUpdate(String[] data) {
  int index = int(data[1]);
  if (Player.doesExist(index)) {
    Player player = Player.instances.get(index);
    int x = int(data[2]);
    int y = int(data[3]);
    player.setPosition( x, y );
  }
}

void nameUpdate(String[] data) {
  int index = int(data[1]);
  if (Player.doesExist(index)) {
    Player player = Player.instances.get(index);
    player.name = data[2];
  }
}

void draw_players() {
  for (int i : Player.instances.keySet()) {
    Player player = Player.instances.get(i);
    player.draw();
  }
}

void draw_players_trails(PGraphics canvas) {
  for (int i : Player.instances.keySet()) {
    Player player = Player.instances.get(i);
    player.draw_trails(canvas);
  }
}

void update_players(int dt) {
  for (int i : Player.instances.keySet()) {
    Player player = Player.instances.get(i);
    player.update(dt);
  }
}

