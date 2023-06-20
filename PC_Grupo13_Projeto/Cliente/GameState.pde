class GameState{
  Player player;
  Player enemy;
  ArrayList<Bonus> bonus;
  ArrayList<Score> scores;
  
  
  GameState(){
    this.player = new Player();
    this.enemy = new Player();
    this.bonus = new ArrayList<Bonus>();
    this.scores = new ArrayList<Score>(2);
  }
  
  synchronized GameState get(){
    GameState res = new GameState();
    res.player = this.player.clone();
    res.enemy = this.enemy.clone();
    
    ArrayList<Bonus> b1 = new ArrayList<Bonus>();
    for(Bonus b: this.bonus) {
      b1.add(b.clone());
    }
    res.bonus = b1;
    
    ArrayList<Score> s = new ArrayList<Score>(2);
    for(Score score: this.scores) {
      s.add(score);
    }
    res.scores = s;
    return res;
  }
  
  synchronized void set(GameState gs) {
    this.player = new Player(gs.player);
    this.enemy = new Player(gs.enemy);
    this.bonus = new ArrayList<Bonus>();
    for(Bonus b : gs.bonus){
      this.bonus.add(b);
    }
    this.scores = new ArrayList<Score>(2);
    for(Score s: gs.scores) {
      this.scores.add(s);
    }
  }
}

class Score {
  String username;
  int score;

  Score(String username, int score) {
    this.username = username;
    this.score = score;
  }
}
  
