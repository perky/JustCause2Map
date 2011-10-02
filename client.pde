class NetClient {
  Client client;
  PApplet p5;
  public boolean isOn;
  int timer;
  int ping_interval = 10000;
  String name;

  NetClient(PApplet p5) {
    this.p5 = p5;
  }

  void start(String ip, String name) {
    if (isOn){return;}
    int port = int(portField.getText());
    client = new Client(p5, ip, port);
    isOn = true;
    this.name = name;
    isConnected = true;
    Player.instances.remove(0);
    local_player = null;
    send_message( ""+MSG_HANDSHAKE );
  }

  void stop() {
    if (isOn) {
      client.stop();
      isOn = false;
      isConnected = false;
    }
  }

  void update(int dt) {
    if (!isOn) { 
      return;
    }
    
    timer += dt;
    if (timer > ping_interval && local_player != null){
      timer = 0;
      send_message( MSG_PING + "," + local_player.id );
    }

    String stringIn;
    String[] data = null;
    if (client.available() > 0) {
      stringIn = client.readStringUntil(byte(MSG_END));
      if (stringIn != null) {
        data = splitTokens(stringIn, ",*" );
      }
      if (data != null) {
        switch (int(data[0])) {
        case MSG_CLIENT_CONNECT:
          clientConnected(data);
          break;
        case MSG_CLIENT_DISCONNECT: 
          clientDisconnected(data); 
          break;
        case MSG_POSITION_UPDATE:
          positionUpdate(data);
          break;
        case MSG_NAME_UPDATE:
          nameUpdate(data);
          break;
        case MSG_HANDSHAKE:
          onHandshake(data);
          break;
        }
      }
    }
  }
  
  void onHandshake(String[] data) {
    int index = int(data[1]);
    if(local_player == null) {
      local_player = new Player("", index);
      local_player.name = name;
      // send name.
      send_message(MSG_NAME_UPDATE + "," + local_player.id + "," + name);
      println("got handshake: "+local_player.id);
    }
    connectButton.setVisible( false );
    ipField.setVisible( false );
    nameField.setVisible( false );
    portField.setVisible( false );
  }

  void clientConnected(String[] data) {
    // Check if it exists.
    int index = int(data[1]);
    if (!Player.doesExist(index)) {
      Player player = new Player("", index);
      if(data.length < 3){
        player.name = "";
      } else {
        player.name = data[2];
      }
      println("client connected: "+index);
    }
  }

  void clientDisconnected(String[] data) {
    int index = int(data[1]);
    if (Player.doesExist(index)) {
      Player.instances.remove(index);
    }
  }
}

