class Reader extends Thread {
  BufferedReader b;
  String username;
  
  Reader(BufferedReader in, String username) {
    this.b = in;
    this.username = username;
  }
  
  public void run(){
    //println(this.username);
    while(true){
      try {
        String info = this.b.readLine();
        //println(info);
        if (info.equals("MatchOverBegin")){
          ArrayList<Score> scoreBoard = new ArrayList<Score>();
          info = this.b.readLine();
          //println(info);
          while (!info.equals("MatchOverEnd")) {
            //println("Dentro do while: " + info);
            String[] fields = info.split(",");
            //println(fields[1] + " " + fields[2]);
            scoreBoard.add(new Score(fields[1], Integer.parseInt(fields[2])));
            info = this.b.readLine();
          }
          //println(scoreBoard);
          GameState gs = gameState.get();
          gs.scores = scoreBoard;
          gameState.set(gs);
          matchScreen.set(false);
          scoreBoardMenu.set(true);
          break;
        }
        //waiting for match to begin (waiting for player)
        else if (info.equals("StartInitialMatchInfo")){
          GameState gs = new GameState();
          info = this.b.readLine();
          //print(info);
          while (!info.equals("EndInitialMatchInfo")){
            String[] fields = info.split(",");  //P,username,posx,posy,angle,isEnemy
            if(fields[0].equals("P")){
              // user da interface
              if (fields[1].equals(this.username)){
                //username, posx, posy, angle, isEnemy
                gs.player = new Player(this.username, Float.parseFloat(fields[2]), Float.parseFloat(fields[3]), Float.parseFloat(fields[4]), Integer.parseInt(fields[5]), false);
              } else {
                //enemy
                gs.enemy = new Player(fields[1], Float.parseFloat(fields[2]), Float.parseFloat(fields[3]), Float.parseFloat(fields[4]), Integer.parseInt(fields[5]), true);
              }
            }
            else if (fields[0].equals("B")){
              if(fields[1].equals("acel")){
                gs.bonus.add(new Bonus(Float.parseFloat(fields[2]),Float.parseFloat(fields[3]),0));
              }
              else if(fields[1].equals("direc")){
                gs.bonus.add(new Bonus(Float.parseFloat(fields[2]),Float.parseFloat(fields[3]),1));
              }
              else if(fields[1].equals("remove")){
                gs.bonus.add(new Bonus(Float.parseFloat(fields[2]),Float.parseFloat(fields[3]),2));
              }
            }
            info = this.b.readLine();
          }
          gameState.set(gs);
          waitMatch.set(false);
          matchScreen.set(true);
        } 
        else if (info.equals("StartMatchInfo")){ //jogo a decorrer
          GameState gs = gameState.get();
          info = this.b.readLine();
          //println(info);
          while(!info.equals("EndMatchInfo")){
            //println("here");
            String[] fields = info.split(",");
            if(fields[0].equals("P")){
              //user da interface
              if(fields[1].equals(this.username)){
                gs.player.username = this.username;
                gs.player.movement(Float.parseFloat(fields[2]), Float.parseFloat(fields[3]), Float.parseFloat(fields[4]));
                gs.player.setScore(Integer.parseInt(fields[5]));
              }
              else{
                //inimigo
                 gs.enemy.username = fields[1];
                 gs.enemy.movement(Float.parseFloat(fields[2]), Float.parseFloat(fields[3]), Float.parseFloat(fields[4]));
                 gs.enemy.setScore(Integer.parseInt(fields[5]));
              }
             }
             else if(fields[0].equals("B")){
               int type = -1;
               if(fields[1].equals("acel")){
                 type = 0;
               }
               else if(fields[1].equals("direc")){
                 type = 1;
               }
               else if(fields[1].equals("remove")){
                 type = 2;
               }
               float x = Float.parseFloat(fields[2]);
               float y = Float.parseFloat(fields[3]);
               int i = Integer.parseInt(fields[4]);
               gs.bonus.set(i, new Bonus(x,y,type));
             }
             gameState.set(gs);
             info = this.b.readLine();
          }
        gameState.set(gs);
        }
        
      } catch (Exception e) {
        e.printStackTrace();
        break;
      }
    }
  }
}
