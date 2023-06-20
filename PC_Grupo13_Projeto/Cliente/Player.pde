import java.lang.Comparable;

class Player {
  PVector position;
  String username;
  float direction;
  float raio;
  int score;
  boolean isEnemy;
  
  Player(){
    this.position = new PVector(0,0);
    this.username = "";
    this.direction = 0;
    this.raio = 0;
    this.score = 0;
    this.isEnemy = false;
  }
  
  Player(String usr, float posx, float posy, float angle, int score, boolean isEnemy){
    this.position = new PVector(posx, posy);
    this.username = usr;
    this.direction = angle;
    this.raio = 20;
    this.score = score;
    this.isEnemy = isEnemy;
  }
  
  Player(Player p){
    this.position = new PVector(p.getPosition().x , p.getPosition().y);
    this.username = p.getUsername();
    this.direction = p.getDirection();
    this.raio = p.getRaio();
    this.score = p.getScore();
    this.isEnemy = p.getIsEnemy();
  }
  
  PVector getPosition(){
    return this.position.copy();
  }
  
  String getUsername() {
    return this.username;
  }
  
  float getDirection(){
    return this.direction;
  }
  
  float getRaio(){
    return this.raio;
  }
  
  synchronized int getScore(){
    return this.score;
  }
  
  synchronized void setScore(int score){
    this.score = score;
  }
  
  boolean getIsEnemy() {
    return this.isEnemy;
  }
  
  synchronized void movement(float newx, float newy, float newDirection){
    this.position = new PVector(newx, newy);
    this.direction = newDirection;
  }
    
  void show() {
    strokeWeight(4);
    if (this.isEnemy){
      stroke(237, 109, 104);
      fill(166, 24, 18);
    }
    else {
      stroke(3, 102, 252);
      fill(0,0,255);
    }
    ellipse(position.x, position.y, raio*2, raio*2);
    strokeWeight(3);
    line(position.x,position.y,position.x + raio*cos(direction),position.y - raio*sin(direction));
    textSize(18);
    textAlign(CENTER,TOP);
    text(this.username + " " + this.score, position.x, (position.y - this.raio) - 25);
    strokeWeight(1);
    stroke(0);
    fill(0);
}
  
  Player clone() {
    return new Player(this);
  }
  
  String toString(){
    return this.username;
  }
}
