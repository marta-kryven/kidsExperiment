// Prim's algortithm for generating random mazes

// create a random world layout
void setupWorld() {
  world.newPrimWorld();
  randomGoal();
  randomAgent();
}


// assign the agent to a random location
void randomAgent() {

  println("generating random agent location...");
  int x = 0, y = 0;

  do {
    x = (int)random(worldw);
    y = (int)random(worldh);
  } while (gridworld[x][y] != 0);

  agent.xnow  = x;  
  agent.ynow  = y;
}


void randomGoal() {
  boolean goalplaced =  false;
  while (!goalplaced) {
    int x = (int)random(worldw);
    int y = (int)random(worldh);
    
    if (x > 0 || y > 0) {
      if (gridworld[x][y] == 0) {
        gridworld[x][y] = S_landmark;
        goalplaced = true;
      }
    }
  }
}


class gridWorld {
  
  ArrayList<cell> cells;
  ArrayList<cell> walls;
  
  cell[] neigh = {new cell(0,1), new cell(1,0), new cell (-1,0), new cell(0,-1)}; 
      
  gridWorld() {
  }
  
  void reset(){
    cells = new ArrayList<cell>();
    walls = new ArrayList<cell>();
  }
  
  void printWorld() {
    for (int j = 0; j < worldh; j++) {
        for (int i = 0; i < worldw; i++) {
          if (listedCell(i,j)) {
            print("c");
          } else if (listedWall(i,j)){
            print("w");
          }
          print(gridworld[i][j], " ");
        }
        println();
      }
  }
  
  void newPrimWorld() {
      
      reset();
      
      gridworld = new int[worldw][worldh];
      
       // distribute random seeds for prim's algorithm
      for (int i = 0; i < worldw; i++) {
        for (int j = 0; j < worldh; j++) {
          gridworld[i][j]=S_wall;
        }
      }
    
      for (int i = 0; i < worldw; i += 2) {
        for (int j = 0; j < worldh; j += 2) {
          gridworld[i][j]=0;
        }
      }
      
  //    println("world");
  //    printWorld();
      // run generation
      
      // this will be the starting cell
      int x = (int)random(worldw);
      int y = (int)random(worldh);
      gridworld[x][y]=0;
      cell c = new cell(x,y);
      cells.add(c);
      
   //   println("start cell");
   //   printWorld();
      
      addNeighb(x,y);
      
  //    println("added neighs");
  //    printWorld();
      
      while (true) {
          boolean terminate = false;
          
          // select a wall to dismount on the next step
          
          int numbersampled = 0;
          cell w;
          int randomwall = -1;
          
          do {
            // select a random wall
            randomwall = (int)random(walls.size());
            w = walls.get(randomwall);
            
            // if this wall has only one cell neighbour on the list
            int cellneigh = 0;
            for (int i = 0; i < neigh.length; i++) {     
             if (exists(w.x+neigh[i].x, w.y+neigh[i].y)) {
               if (listedCell(w.x+neigh[i].x, w.y+neigh[i].y)) {
                 cellneigh++;
               }
             }
           }
           
           if (cellneigh == 1) {
             terminate = true;
           } else {
             numbersampled++;
     //        println("wall ", w.x, ",", w.y, " neighs ", cellneigh);
           }
          } while(!terminate && numbersampled < walls.size()*5);
          
          // if found a wall to dismount
          if (terminate) {
            
    //        println("selected wall ", w.x, ",", w.y);
    //        printWorld();
      
            // convert this wall to a cell
            gridworld[w.x][w.y] = 0;
            
            // remove this wall from the wall list
            walls.remove(randomwall);
            
            // add it to the cells list
            cells.add(w);
            
    //        println("removed wall, added cell ", w.x, ",", w.y);
     //       printWorld();
            
            // add the cell's neighbours
            addNeighb(w.x, w.y);
            
      //      println("added cell neighs ", w.x, ",", w.y);
      //      printWorld();
          } else {
      //      println("sampled ",numbersampled );
            break;
          }
      }
      
  }
  
  boolean listedWall(int x, int y) {
    for (int i = 0; i < walls.size(); i++) {
      cell w = walls.get(i);
      if (w.x == x && w.y == y) {
        return true;
      }
    }
    return false;
  }
  
  boolean listedCell(int x, int y) {
    for (int i = 0; i < cells.size(); i++) {
      cell w = cells.get(i);
      if (w.x == x && w.y == y) {
        return true;
      }
    }
    return false;
  }
  
  void addNeighb(int x, int y) {
    // add all neighbours
      for (int i = 0; i < neigh.length; i++) {  
         int cx = x+neigh[i].x;
         int cy = y+neigh[i].y;
         
         if (exists(cx, cy)) {
           // if it is a wall
           if (wall(cx, cy)) { 
             // if it is not yet on the list of walls
             if (!listedWall(cx, cy)) {
               walls.add(new cell(cx, cy));
             }
             
           } else {
             // if it is empty
             // if it is not yet on the list of cells
             if (!listedCell(cx, cy)) {
               cells.add(new cell(cx, cy));
               addNeighb(cx, cy);
             }
           }
         }
         
         
      }
  }
  
  
}