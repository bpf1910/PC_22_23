class Bonus{
  PVector position;
  float raio;
  int tipo; //0 - aceleraçao, 1 - direçao, 2 - reset bonus
  
  Bonus(){
    this.position = new PVector(0,0);
    this.raio = 0;
    this.tipo = 0;
  }
  
  Bonus(float x, float y, int tipo){
    this.position = new PVector(x,y);
    this.raio = 10;
    this.tipo = tipo;
  }
  
  Bonus(Bonus b){
    this.position = b.getPosition();
    this.raio = b.getRaio();
    this.tipo = b.getTipo();
  }
  
  PVector getPosition() {
    return this.position.copy();
  }
  
  float getRaio(){
    return this.raio;
  }
  
  int getTipo(){
    return this.tipo;
  }
  
  void showBonus(){
    if(this.tipo == 0){
      fill(11,3,252); // azul bonus aceleracao
      ellipse(this.position.x, this.position.y, this.raio, this.raio);
    }
    else if(this.tipo == 1){
      fill(0,255,0); //verde bonus direçao
      ellipse(this.position.x, this.position.y, this.raio, this.raio);
    }
    else if(this.tipo == 2){
      fill(255,0,0); //vermelho remove bonus
      ellipse(this.position.x, this.position.y, this.raio, this.raio);
    }
  }
  
  Bonus clone(){
    return new Bonus(this);
  }
}
