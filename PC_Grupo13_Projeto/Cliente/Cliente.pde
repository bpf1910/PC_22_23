import java.io.InputStreamReader;
import java.net.Socket;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.Arrays;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

int x = 160;
int y = 32;

// Variáveis para serem usadas para comunicar com o servidor através de um socket
Socket s;
BufferedReader fromSocket;
PrintWriter toSocket;
Thread reader = null;
GameState gameState = new GameState();

AtomicBoolean mainMenu = new AtomicBoolean(true);
AtomicBoolean loginMenu = new AtomicBoolean(false); //fazer login?
AtomicBoolean logoutMenu = new AtomicBoolean(false); //fazer logout?
AtomicBoolean registerMenu = new AtomicBoolean(false); //fazer registo?
AtomicBoolean unregisterMenu = new AtomicBoolean(false); //fechar conta?
AtomicBoolean onlineMenu = new AtomicBoolean(false);
AtomicBoolean waitMatch = new AtomicBoolean(false);
AtomicBoolean matchScreen = new AtomicBoolean(false);
AtomicBoolean usr = new AtomicBoolean(true); //colocar username?
AtomicBoolean pswd = new AtomicBoolean(false); //colocar password?
AtomicBoolean messageMenu = new AtomicBoolean(false);
AtomicBoolean success = new AtomicBoolean(false);
AtomicBoolean scoreBoardMenu = new AtomicBoolean(false);
AtomicBoolean onlineListMenu = new AtomicBoolean(false);

String usrText = ""; //username
String pswdText = ""; //password
String message = "";
List<String> listOnline = new ArrayList<String>();

boolean inRect(float x, float y, float w, float h) {
    if ((x <= mouseX && mouseX <= x + w) && (y <= mouseY && mouseY <= y + h))
        return true;
    else
        return false;
}

String coded(String text) {
    String res = "";
    for(int i=0; i<text.length(); i++)
        res += "*";
    return res;
}

String getChar(String myText) {
  if (keyCode == BACKSPACE) {
    if (myText.length() > 0)
      myText = myText.substring(0, myText.length()-1);
  } else if (keyCode == DELETE)
    myText = "";
  else if (keyCode != SHIFT && keyCode != CONTROL && keyCode != ALT)
    myText = myText + key;
  return myText;
}

void mouseClicked() {
  if (messageMenu.get()){
    if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
      if(!success.get())
        mainMenu.set(true);
      message = "";
      success.set(false);
      messageMenu.set(false);
    }
  }
  else if(mainMenu.get()){
     // Botao Login
    if (inRect(width/2 - x/2, height/2 - y, x, y)) {
      loginMenu.set(true);
      mainMenu.set(false);
      // Botao Create Account
    } else if (inRect(width/2 - x/2, height/2 + y, x, y)) {
      registerMenu.set(true);
      mainMenu.set(false);
      // Botao Close Account
    } else if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
      unregisterMenu.set(true);
      mainMenu.set(false);
    }
  }
  else if(loginMenu.get() || registerMenu.get() || unregisterMenu.get()){
    // Botao voltar
    if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
      mainMenu.set(true);
      usrText = "";
      pswdText = "";
      usr.set(true);
      pswd.set(false);
      if(loginMenu.get()){
        loginMenu.set(false);
      } else if(registerMenu.get()){
        registerMenu.set(false);
      } else if(unregisterMenu.get()){
        unregisterMenu.set(false);
      }
    }
  }
  else if (onlineMenu.get()){
    // BOTAO JOGAR
    if (inRect(width/2 - x/2, height/2 - y, x, y)) {
      reader = null;
      //String message = "jogar," + usrText;
      //println(message);
      toSocket.println("jogar," + usrText);
      toSocket.flush();
      onlineMenu.set(false);
      waitMatch.set(true);
      try {
        if (reader == null) {
          // Criar uma thread para ler do socket
          reader = new Reader(fromSocket, usrText);
          reader.start();
        }
      } catch (Exception e) {
        exit();
      }
    //BOTAO LOGOUT
    } else if (inRect(width/2 - x/2, height/2 + y, x, y)){
      logout(usrText);
    }
    //BOTAO ONLINE
    else if(inRect(width/2 - x/2, height/2 + 3*y, x, y)){
      online();
    }
  }
  else if (scoreBoardMenu.get()){
    //Botao de Logout
    if (inRect(width/2 - x - x/5, height/2 + 3*y, x, y)) {
      reader = null;
      logout(usrText);
      //println(usrText);
      GameState gs = new GameState();
      gameState.set(gs);
     //Botao de Menu de Jogo
    } else if (inRect(width/2 + x/5, height/2 + 3*y, x, y)) {
      //println(usrText);
      toSocket.println("continue");
      toSocket.flush();
      reader = null;
      GameState gs = new GameState();
      gameState.set(gs);
      scoreBoardMenu.set(false);
      onlineMenu.set(true);
    }
  }
  else if(onlineListMenu.get()){
    if(inRect(width/2 - x/2, height/2 + 6*y, x, y)){
      listOnline = new ArrayList<>();
      onlineMenu.set(true);
      onlineListMenu.set(false);
    }
  }
}

void keyPressed(){
  if(matchScreen.get()) {
    if (key == 'w') {
        toSocket.println("KeyChanged,up,True");
      }
      if (key == 'a') {
        toSocket.println("KeyChanged,left,True");
      }
      if (key == 'd') {
        toSocket.println("KeyChanged,right,True");
      }
      toSocket.flush();
    }
  else if(loginMenu.get() || registerMenu.get() || unregisterMenu.get()) {
    //inserir nome do utilizador
    if(usr.get()){
      if(keyCode == ENTER){
        usr.set(false);
        pswd.set(true);
      } else{
        usrText = getChar(usrText);
      }
    //inserir password
    } else if (pswd.get()){
      if(keyCode == ENTER){
        pswd.set(false);
        if(loginMenu.get()) {
          login(usrText, pswdText);
        } else if(registerMenu.get()){
          create_account(usrText, pswdText);
        } else if(unregisterMenu.get()){
          close_account(usrText, pswdText);
        }
      }
      else {
        pswdText = getChar(pswdText);
      }
    }
  }
}

void keyReleased() {
  if (matchScreen.get()) {
      if (key == 'w') {
        toSocket.println("KeyChanged,up,False");
      }
      if (key == 'a') {
        toSocket.println("KeyChanged,left,False");
      }
      if (key == 'd') {
        toSocket.println("KeyChanged,right,False");
      }
      toSocket.flush();
  }
}

void setup(){
  size(500,500);
  try {
    // Conectar com o servidor e criar um socket
    s = new Socket("localhost", 4001);
    // Criar um objeto para ler do socket e um para escrever para o socket
    fromSocket = new BufferedReader(new InputStreamReader(s.getInputStream()));
    toSocket = new PrintWriter(s.getOutputStream());
  } catch (Exception e) {
    showMessageDialog(null, "Não foi possível conectar com o servidor!", "Erro", INFORMATION_MESSAGE);
    exit();
    return;
  }
}

void draw(){
    background(32);
    //MESSAGE
    if (messageMenu.get()){
      showMessage();
    }
    //MAIN MENU
    else if(mainMenu.get()){
        showMainMenu();
    }
    //LOGIN, REGISTER, UNREGISTER MENUS
    else if (loginMenu.get() || registerMenu.get() || unregisterMenu.get()){
        showLoginRegisterUnregisterMenu();
    }
    //ONLINE MENU: JOGAR ETC
    else if (onlineMenu.get()){
      showOnlineMenu();
    }
    else if (onlineListMenu.get()){
      showOnlineListMenu();
    }
    //À ESPERA DE PLAYER
    else if (waitMatch.get()){
      showWaitMatch();
    }
    //PARTIDA
    else if (matchScreen.get()){
      showMatchScreen();
    }
    //FINAL DE UMA PARTIDA
    else if (scoreBoardMenu.get()){
      showScoreBoardScreen();
    }
}

void showMessage() {
  background(32);
  textSize(32);
  fill(255,255,0);
  textAlign(CENTER,CENTER);
  text(message, width/2, height/2);

  //Botao OK
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
    strokeWeight(3.5);
    stroke(255, 255, 255);
  }
  fill(#3B6BAD);
  rect(width/2 - x/2, height/2 + 3*y, x, y, 10);
  fill(255);
  textSize(24);
  textAlign(CENTER, CENTER);
  text("Ok", width/2, height/2 + 3*y + y/2 - 4);
}

void showMainMenu() {
    //stroke(0, 0, 0);
    textSize(75);
    //cor do texto
    fill(255);
    textAlign(CENTER,CENTER);
    text("NOVA ARENA", width/2, height/5);

    //BOTAO LOGIN
    strokeWeight(0);
    stroke(211, 211, 211);
    if (inRect(width/2 - x/2, height/2 - y, x, y)) {
        strokeWeight(3.5);
        stroke(255, 255, 255);
    }
    fill(#3B6BAD);
    rect(width/2 - x/2, height/2 - y, x, y, 10);
    textSize(26);
    fill(255);
    textAlign(CENTER, CENTER);
    text("Login", width/2, height/2 - y/2);

    //BOTAO REGISTO
    strokeWeight(0);
    stroke(211, 211, 211);
    if (inRect(width/2 - x/2, height/2 + y, x, y)) {
        strokeWeight(3.5);
        stroke(255, 255, 255);
    }
    fill(#3B6BAD);
    rect(width/2 - x/2, height/2 + y, x, y, 10);
    fill(255);
    textAlign(CENTER, CENTER);
    text("Registo", width/2, height/2 + y + y/2);

    //BOTAO FECHAR CONTA
    strokeWeight(0);
    stroke(211, 211, 211);
    if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
        strokeWeight(3.5);
        stroke(255, 255, 255);
    }
    fill(#3B6BAD);
    rect(width/2 - x/2, height/2 + 3*y, x, y, 10);
    fill(255);
    textAlign(CENTER, CENTER);
    text("Fechar conta", width/2, height/2 + 3*y + y/2);

    fill(255);
    textSize(15);
    text("Prog. Concorrente 22/23", width - 85, height - 15);
}

void showLoginRegisterUnregisterMenu(){
    textSize(50);
    textAlign(CENTER,CENTER);
    if(loginMenu.get()) {
        fill(255);
        text("Login", width/2, height/5);
    } else if(registerMenu.get()) {
        fill(255);
        text("Registo", width/2, height/5);
    } else if(unregisterMenu.get()) {
        fill(255);
        text("Fechar conta", width/2, height/5);
    }

    //fill Username
    strokeWeight(0);
    stroke(211, 211, 211);
    fill(255);
    rect(width/2 - x/2, height/2 - y, x, y);
    textSize(24);
    fill(0);
    textAlign(CENTER, CENTER);
    text(usrText, width/2, height/2 - y/2 - 4);

    //fill Password
    strokeWeight(0);
    stroke(211, 211, 211);
    fill(255);
    rect(width/2 - x/2, height/2 + y, x, y);
    fill(0);
    textAlign(CENTER, CENTER);
    text(coded(pswdText), width/2, height/2 + y + y/2 - 4);

    //Botao de recuar
    strokeWeight(0);
    stroke(211, 211, 211);
    if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
        strokeWeight(3.5);
        stroke(255, 255, 255);
    }
    fill(#3B6BAD);
    rect(width/2 - x/2, height/2 + 3*y, x, y, 10);
    fill(255);
    textAlign(CENTER, CENTER);
    text("Recuar", width/2, height/2 + 3*y + y/2 - 4);
}

void showOnlineMenu(){
  textSize(75);
  //cor do texto
  fill(255);
  textAlign(CENTER,CENTER);
  text("NOVA ARENA", width/2, height/5);
  
  //BOTAO JOGAR
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x/2, height/2 - y, x, y)) {
    strokeWeight(3.5);
    stroke(255, 255, 255);
  }
  
  fill(#3B6BAD);
  rect(width/2 - x/2, height/2 - y, x, y, 10);
  textSize(24);
  fill(255);
  textAlign(CENTER, CENTER);
  text("Jogar", width/2, height/2 - y/2);
  
  //BOTAO LOGOUT
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x/2, height/2 + y, x, y)) {
      strokeWeight(3.5);
      stroke(255, 255, 255);
  }
  fill(#3B6BAD);
  rect(width/2 - x/2, height/2 + y, x, y, 10);
  fill(255);
  textAlign(CENTER, CENTER);
  text("Logout", width/2, height/2 + y + y/2);
  
  //BOTAO ONLINE
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x/2, height/2 + 3*y, x, y)) {
      strokeWeight(3.5);
      stroke(255, 255, 255);
  }
  fill(#3B6BAD);
  rect(width/2 - x/2, height/2 + 3*y, x, y, 10);
  fill(255);
  textAlign(CENTER, CENTER);
  text("Online", width/2, height/2 + 3*y + y/2);
    
    
}

void showWaitMatch() {
  textSize(32);
  fill(255);
  textAlign(CENTER,CENTER);
  text("À espera de adversário...", width/2, height/2);
}

void showMatchScreen(){
  background(32);
  
  GameState gs = gameState.get();
  Player player = gs.player;
  Player enemy = gs.enemy;
  ArrayList<Bonus> bonus = gs.bonus;
  
  for (int i = 0; i < bonus.size(); i++) {
    bonus.get(i).showBonus();
  }
  
  player.show();
  enemy.show();
}

void showScoreBoardScreen(){
  GameState gs = gameState.get();
  ArrayList<Score> scores = gs.scores;
  textSize(50);
  fill(255);
  textAlign(CENTER,CENTER);
  text("FIM DA PARTIDA", width/2, height/5);
  textSize(40);
  for (int i = 0; i < scores.size(); i++) {
    Score s = scores.get(i);
    fill(255);
    if (s.username.equals(gs.player.getUsername()))
      fill(255);
    text((i+1) + "º: " + s.username + " - " + s.score, width/2, height/2 + i*60 - 60);
  }
  
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x - x/5, height/2 + 3*y, x, y)) {
    strokeWeight(3.5);
    stroke(255, 255, 255);
  }
  fill(#3B6BAD);
  rect(width/2 - x - x/5, height/2 + 3*y, x, y, 10);
  fill(255);
  textSize(24);
  text("Logout", width/2 - x/2 - x/5, height/2 + 3*y + y/2);

  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 + x/5, height/2 + 3*y, x, y)) {
    strokeWeight(3.5);
    stroke(255, 255, 255);
  }
  
  fill(#3B6BAD);
  rect(width/2 + x/5, height/2 + 3*y, x, y, 10);
  fill(255);
  textSize(24);
  text("Menu de Jogo", width/2 + x/2 + x/5, height/2 + 3*y + y/2);
}

void showOnlineListMenu(){
  textSize(40);
  fill(255);
  textAlign(CENTER,CENTER);
  text("JOGADORES ONLINE", width/2, height/6);
  textSize(20);
  int i = 0;
  textAlign(CENTER, CENTER);
  for(String name : listOnline){
    name = name.replace("\"","");
    if(i<8){
      text((i+1) + ": " + name, width/2, height/2 + i*30 - 90);
      i++;
    }
    else{
      break;
    }
  }
  textAlign(CENTER,CENTER);
  
  strokeWeight(0);
  stroke(211, 211, 211);
  if (inRect(width/2 - x/2, height/2 + 6*y, x, y)) {
    strokeWeight(3.5);
    stroke(255, 255, 255);
  }
  
  fill(#3B6BAD);
  rect(width/2 - x/2, height/2 + 6*y, x, y, 10);
  fill(255);
  textSize(24);
  text("Voltar", width/2, height/2 + 6*y + y/2);
}


void exit() {
  try {
    s.close();
  } catch (Exception e) {}
  super.exit();
}
