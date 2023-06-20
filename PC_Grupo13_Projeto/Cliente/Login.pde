import static javax.swing.JOptionPane.*;
import javax.swing.JPasswordField;

void login(String username, String password) {
  if (password == null)
    return;

  //println("login," + username + "," + password);
    
  toSocket.println("login," + username + "," + password);
  toSocket.flush();
  
  try {
    String answer = fromSocket.readLine();
    //println(answer);
    loginMenu.set(false);
    messageMenu.set(true);
    if (answer.equals("LoginDone")) {
      message = "Bem-vindo " + username;
      success.set(true);
      onlineMenu.set(true);
    } else if (answer.equals("LoginInvalid")) {
      message = "Login Invalido";
      usrText = "";
      success.set(false);
    } else if (answer.equals("AlreadyLoggedIn")) {
      message = "O utilizador já tem sessão iniciada!";
      usrText = "";
      success.set(false);
    }
  } catch (Exception e) {}
  
  pswdText = "";
  usr.set(true);
  pswd.set(false);
}

void create_account(String username, String password) {
  if (password == null)
    return;

  //println("create_account," + username + "," + password);
  toSocket.println("create_account," + username + "," + password);
  toSocket.flush();

  try {
    String answer = fromSocket.readLine();
    registerMenu.set(false);
    messageMenu.set(true);
    if (answer.equals("Registered")) {
      message = "Conta criada com sucesso";
      List<String> lines = new ArrayList<>();
      try { 
        lines = Files.readAllLines(Paths.get("C:\\Users\\pires\\Documents\\Universidade\\PC\\Nova_Arena\\logs.txt"), StandardCharsets.UTF_8);
        //println(lines.get(1));
      }
      catch(IOException exc) { 
        System.out.println(exc.getMessage()); 
      }
      String newLine = (username + "," + password);
      lines.add(newLine);
      writeLog("C:\\Users\\pires\\Documents\\Universidade\\PC\\Nova_Arena\\logs.txt", lines);
      success.set(true);
      usrText = "";
      mainMenu.set(true);
    } else if (answer.equals("UserExists")) {
      message = "Já existe um utilizador com esse nome!";
      usrText = "";
      success.set(false);
    }
  } catch (Exception e) {}
  
  pswdText = "";
  usr.set(true);
  pswd.set(false);
}

void close_account(String username, String password) {
   if (password == null)
      return;

    toSocket.println("close_account," + username + "," + password);
    toSocket.flush();

    try {
      String answer = fromSocket.readLine();
      unregisterMenu.set(false);
      messageMenu.set(true);
      if (answer.equals("AccountClosed")) {
        message = "Conta apagada com sucesso";
        List<String> lines = new ArrayList<>();
        try { 
          lines = Files.readAllLines(Paths.get("C:\\Users\\pires\\Documents\\Universidade\\PC\\Nova_Arena\\logs.txt"), StandardCharsets.UTF_8);
          //println(lines);  
      }
        catch(IOException exc) { 
          System.out.println(exc.getMessage()); 
        }
        String newLine = (username + "," + password);
        removeFromFile("C:\\Users\\pires\\Documents\\Universidade\\PC\\Nova_Arena\\logs.txt", lines, newLine);
        success.set(true);
        usrText = "";
        mainMenu.set(true);
      } else if (answer.equals("CloseAccountGoneWrong")) {
        message = "Erro ao fechar conta";
        success.set(false);
        usrText = "";
        mainMenu.set(true);
      }
    } catch (Exception e) {}
    
  pswdText = "";
  usr.set(true);
  pswd.set(false);
}

void logout(String username) {
  toSocket.println("logout," + username);
  toSocket.flush();

  try {
    String answer = fromSocket.readLine();
    mainMenu.set(false);
    messageMenu.set(true);
    //println(answer);
    if (answer.equals("LogoutDone")) {
      message = "Logout feito";
      usrText = "";
      success.set(true);
      mainMenu.set(true);
      if(onlineMenu.get()){
        onlineMenu.set(false);
      }
      else if (scoreBoardMenu.get()) {
        scoreBoardMenu.set(false);
      }
    } else if (answer.equals("LogoutInvalid")) {
      message = "Logout Invalido";
      success.set(false);
    }
  } catch (Exception e) {}

  pswdText = "";
  usr.set(true);
  pswd.set(false);
}

void online(){
  toSocket.println("online");
  toSocket.flush();
  
  try{
    String answer = fromSocket.readLine();
    answer = answer.replace("[","");
    answer = answer.replace("]","");
    for(String name : answer.split(",")){
      listOnline.add(name);
    }
    onlineListMenu.set(true);
    onlineMenu.set(false);
    //println(listOnline.get(0));
  }
  catch (Exception e) {}
}

void lerLog(String file) {
  List<String> linhas = lerFicheiro(file); 
  String [] s;
  for(String linha : linhas){
    s = linha.split(",");
    toSocket.println("create_account," + s[0] + "," + s[1]);
    toSocket.flush();
  }
}

void writeLog(String filePath, List<String> lines){
  //println(lines);
  try {
    PrintWriter pw = new PrintWriter(filePath);
    for (String line : lines){
      pw.println(line);
    }
    pw.close();
  } catch(IOException exc) { 
    System.out.println(exc.getMessage()); 
  }
}

void removeFromFile(String filePath, List<String> lines, String line){
  int index = 0;
  for (String l : lines){
    if(!l.equals(line)){
      index++;
      continue;
    }
    break;
  }
  lines.remove(index);
  writeLog(filePath, lines);
}

List<String> lerFicheiro(String nomeFich){
  List<String> lines = new ArrayList<>();
  try { 
    lines = Files.readAllLines(Paths.get(nomeFich), StandardCharsets.UTF_8); 
  }
  catch(IOException exc) { 
    System.out.println(exc.getMessage()); 
  }
  return lines;
}
