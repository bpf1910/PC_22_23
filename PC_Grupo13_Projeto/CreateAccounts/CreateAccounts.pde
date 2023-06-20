import java.io.InputStreamReader;
import java.net.Socket;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.Arrays;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

Socket s;
BufferedReader fromSocket;
PrintWriter toSocket;

void setup(){
  try {
    // Conectar com o servidor e criar um socket
    s = new Socket("localhost", 4001);
    // Criar um objeto para ler do socket e um para escrever para o socket
    fromSocket = new BufferedReader(new InputStreamReader(s.getInputStream()));
    toSocket = new PrintWriter(s.getOutputStream());
    
  } catch (Exception e) {
    return;
  }
  
  try{
    lerLog("C:\\Users\\pires\\Documents\\Universidade\\PC\\Nova_Arena\\logs.txt"); //É PRECISO MUDAR EM CADA MAQUINA
    exit();
    return;
  }
  catch(Exception e) {
     System.out.println(e.getMessage());
     exit();
     return;
  }
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

void draw(){
}
