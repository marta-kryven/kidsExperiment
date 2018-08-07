
class Solver {
  
  float[][] Ot;       // sensor model at the current step; 
  boolean has_observed[][]; // keep track of the cells the agent has seen for visualising visual field
  boolean hasSeenTheGoal; // use this to override any noisy actions after the goal position is known
  cell[] A; // actions that may be available
 
  
  Solver() {
    hasSeenTheGoal = false;
    
    A = new cell[4];
    A[0] = new cell (0, 1);
    A[1] = new cell (1, 0);
    A[2] = new cell (-1, 0);
    A[3] = new cell (0, -1); 
    
    reset();
  }
  
  // set the observation table to an undefined state
  void initObserve() {
    
    for (int i = 0; i < worldw; i++) {
      for (int j = 0; j < worldh; j++) {
        Ot[i][j] = 1.0;
      }
    }
  }
  
  void observe(int x, int y) {
    if (!exists(x,y)) {
      println("observeing bad cell ", x, ",", y);
      return;
    }
    
    has_observed[x][y] = true;

    if (exists(x, y)) { // the cell address is valid
      if (goal(x, y)) { 
        // observing the goal means that all other cells are empty
        for (int i = 0; i < worldw; i++) {
          for (int j = 0; j < worldh; j++) {
            Ot[i][j] = 0;
          }
        }
        Ot[x][y] = 1;
        hasSeenTheGoal = true;
      } else {
        Ot[x][y] = 0; 
      }
    } else {
      println("Called 'observe' for a bad cell ", x, ", ", y);
    }
  }
  
  void forward() {
    println("Solver::forward does nothing");
  }
  
  ArrayList<cell> chooseAction(int x, int y) {
    println("Solver::chooseAction does nothing");
    ArrayList<cell> empty = new ArrayList();
    empty.add(new cell(0,0));
    return empty;
  }
  
  // actions that are possible in this cell, are such that do not lead into a wall or outside the map
  ArrayList<cell> getAdmissibleActions(int xnow, int ynow) {
    
    ArrayList<cell> actions = new ArrayList<cell>();
    int n=0;
    
    for (int i = 0; i < A.length; i++) {   
      int x = xnow + A[i].x;
      int y = ynow + A[i].y;  
      if (exists(x, y) && !wall(x, y)) {
        actions.add(new cell(A[i].x, A[i].y, 0, 1, true));
        n++;
      } else {
        actions.add(new cell(A[i].x, A[i].y, 0, 0, false));
      }
    }
    
   // print("admissible at : (", xnow, ynow, ") ");
    for (int i = 0; i < actions.size(); i++) {
      cell c = actions.get(i); 
      if (c.moveExists) {
        c.prob = 1/n;
      } else {
        c.prob = 0;
      }
      
      actions.set(i, c);
     // print(c.getActionName(), c.moveExists, " ");
    }
    //println();
    
    return actions;
  }
  
  void reset() {
    Ot = new float[worldw][worldh];
    has_observed = new boolean[worldw][worldh];

    for (int i = 0; i < worldw; i++) {
      for (int j = 0; j < worldh; j++) {
        if (wall(i, j)) {
          has_observed[i][j] = true;
        } else {
          has_observed[i][j] = false;
        }
        Ot[i][j] = 1.0;
      }
    }
  }
  
  cell choseOneProbabilistically(ArrayList<cell> admissible) {
      // sample a random number from uniformly distributed random numbers
      float randomdie = random(0, 1);
      float cumulativeprob = 0.0;

      println ("choseOneProbabilistically", admissible.size());
      // select an action i with probability proportional to prob
      for (int i = 0; i < admissible.size(); i++) {
        if (admissible.get(i).moveExists) {
          println ("value, prob: ", admissible.get(i).getActionName(), admissible.get(i).value, admissible.get(i).prob);
          
          cumulativeprob += admissible.get(i).prob;
          if (randomdie <= cumulativeprob) {
             return admissible.get(i);
          }
        }
      }
      
      print("No actions available", admissible.size(), ", ");
       for (int i = 0; i < admissible.size(); i++) {
         print(admissible.get(i).getActionName(), ":", admissible.get(i).prob , ",");
       }
      println();
      return new cell(0,0);
  }
  
  
  boolean hasobserved(int i, int j) {
    if (i >= worldw || j >= worldh) {
      println("hasobserved for a bad cell: ", i, j);
      return false;
    } 
    return has_observed[i][j];
  }
  
  
  int numberOfNotSeenCells() {
    int n = 0;
    for (int i = 0; i < worldw; i++) {
      for (int j = 0; j < worldh; j++) {
        if (!has_observed[i][j]) n++;
      }
    }
    return n;
  }
  
};
