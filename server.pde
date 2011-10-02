
class NetServer
{
  Server server;
  PApplet p5;
  public boolean isOn;
  int ping_timeout = 20000;

  NetServer(PApplet p5) {
    this.p5 = p5;
  }

  void start() {
    int port = int(portField.getText());
    this.server = new Server(p5, port);
    isOn = true;
    println("server started");
  }

  void stop() {
    local_player.destroy();
    server.stop();
    isOn = false;
    isConnected = false;
  }

  void update(int dt) {
    if (!isOn) { 
      return;
    }
    
    for (int i : Player.instances.keySet()) {
      Player player = Player.instances.get(i);
      if ( millis() - player.last_ping > ping_timeout && i != 0 ) {
        send_message( MSG_CLIENT_DISCONNECT + "," + player.id );
        player.destroy();
        break;
      }
    }

    // Get the next available client
    Client thisClient = server.available();
    // If the client is not null, and says something, display what it said
    if (thisClient != null) {
      String stringIn = thisClient.readStringUntil(byte(MSG_END));
      if (stringIn != null) {
        String[] data = splitTokens(stringIn, ",*");
        boolean shouldForward = true;
        switch (int(data[0])) {
        case MSG_HANDSHAKE:
          clientConnect(thisClient);
          shouldForward = false;
          break;
        case MSG_POSITION_UPDATE:
          positionUpdate(data);
          break;
        case MSG_NAME_UPDATE:
          nameUpdate(data);
          break;
        case MSG_PING:
          shouldForward = false;
          receivedPing(data);
          break;
        }
        if (shouldForward) {
          println("forwarding: " + stringIn);
          server.write( stringIn );
        }
      }
    }
  }

  void clientConnect(Client client) {
    println("We have a new client: " + client.ip());
    Player player = new Player( client.ip(), -1 );
    player.last_ping = millis();
    println("New player id: "+player.id);
    // Send handshake.
    send_message( MSG_HANDSHAKE + "," + player.id );
    // Now send a list of all clients.
    String data;
    Player otherPlayer;
    for (int i : Player.instances.keySet()) {
      otherPlayer = Player.instances.get(i);
      data = MSG_CLIENT_CONNECT + "," + otherPlayer.id + "," + otherPlayer.name;
      send_message( data );
    }
  }
  
  void receivedPing(String[] data) {
    int index = int(data[1]);
    if (Player.doesExist(index)) {
      Player player = Player.instances.get(index);
      player.last_ping = millis();
    }
  }
}

