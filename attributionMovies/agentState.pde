int maxpath = 100;
int renderDelay=0;

// -------------------------------------------------------- Agent State and draw ---------------------------------
class AgentState {

  int xnow, ynow, dx, dy; // current coordinates in the grid, current offset for motion  
  int angle; // current angle
  int newangle; // target angle during rotation

  String[] path; // path taken by the agent, each step encoded as t(dx, dy) or r(angle1, angle2), dx,dy in (0,1) 
  int pathstep;  // current path length
  String stringpath;

  cell[] motorplan; // autoplilot 
  int posInPath;

  boolean GoalReached = false;

  AgentState(int x, int y, int a) {
    resetAgent();
    xnow = x; 
    ynow = y; 
    angle = a;

    // allocate a large array
    path = new String[maxpath];
    motorplan = null;
    stringpath="p("+x+","+y+");";
   // println("created agent at", x + "," + y);
  }

  String getStringPath() {
    return stringpath;
  }

  void resetAgentPos(int startX, int startY) {
    xnow = startX; 
    ynow = startY;
    stringpath="p(" + startX + "," + startY+ ");";
  //  println("reset agent at", startX + "," + startY);
  }

  // use this every time the world is reinitialised
  void resetAgent() {
    stringpath="";
    GoalReached = false;
    posInPath = 0; // current position in motor plan
    angle = 0;
    dx = 0; 
    dy = 0;
    newangle = 0; 

    gc.resetAgent();
    pathstep = 0;
    path = new String[maxpath];
  }

  // set motor plan, either random or loaded from file
  void setMotorplan(cell[] m) {
    agent.motorplan = m;
    posInPath=0;
    
  /*  print("motorplan: ");
    for (cell c: m) {
      print ( "(", c.x, ",", c.y, ")");
    }
    
    println();*/
  }

  void recordTurn(int angle, int newangle) {
    if (pathstep < maxpath) {
      String s = "r(" + angle + "," + newangle + ")";
      path[pathstep] = s;
      stringpath += s;
      stringpath += ";";
      pathstep++;
    }
  }

  void recordMove(int oldx, int oldy, int x, int y) {
    if (pathstep < maxpath) {
      path[pathstep] = "t(" + (x-oldx) + "," + (y-oldy) + ")";
      String s = "p(" + x + "," + y + ");";
      stringpath += s;
      pathstep++;
    }
  }

  // initiate rotation
  void setTargetAngle(int old, int newa) {
    newangle = newa;
    angle = old;
    gc.rotating = true;

    int mag = abs(abs(newangle) - abs(angle));
    int sign =  (newangle-angle)/abs(newangle-angle);

    if (angle == 180 && newangle == -90) {
      mag = 90;
      sign = 1;
    } else {
      if (mag == 0) mag = 180; // this will happen if he goes from -90 to 90
      if (sign==0) sign = -1;
    }

    newangle = mag*sign;
  }

  // move one cell north, east, west or south; orient in that direction if needed
  void setTargetXYat(cell p) {

  //  println("setTargetXYat", p.x, p.y);
    if ( exists(xnow + p.x, ynow + p.y) ) {

      dx = p.x; 
      dy = p.y;
      gc.moving=true;

      if (angle == 270) angle = -90;
      if (angle == 360) angle = 0;
      if (angle == -270) angle = 90; 
    }
  }

  boolean checkline(float x1, float y1, float px, float py, float step) {
    float dx = (x1-px)/step;
    float dy = (y1-py)/step;

    float fx = px+dx;
    float fy = py+dy;
    int x = floor(fx);
    int y = floor(fy);

    do {
      if (!exists(x, y)) {
    //    println("err: out of map at (", x, ", ", y, ") while checking (", px, ",", py, "), ", "fxfy:", fx, ",", fy);
        return true;
      }
      if (wall(x, y)) return false;

      fx +=dx; 
      fy +=dy;      
      x = floor(fx);  
      y = floor(fy);
    } while (x !=floor(x1) || y !=floor(y1));
    return true;
  }

  void addvisible(int fromx, int fromy, int px, int py, int level, boolean[][] v, int a) {

    if (!exists(px, py)) return;
    v[px][py] = false;

    // make sure he can not see behind him
    if (!omnidirectional) {
      if (a == 0 && py < fromy) return;
      if (a == 180 && py > fromy) return;
      if (a == 90 && px > fromx) return;
      if (a == -90 && px < fromx) return;
    }

    boolean b = true;
    if (level > 1 || (abs(fromx-px) + abs(fromy-py) > 1) /*is a diagonal cell*/ ) {

      // Draw four lines connecting the corners of the current cell and the cell which visibility is being checked.
      // The cell (px,py) is visible from (xnow, ynow) only if all four lines do not intersect walls
      if (b) b = checkline((float)fromx+0.1, float(fromy)+0.1, float(px)+0.1, float(py)+0.1, float(level)*50.0);
      if (b) b = checkline((float)fromx+0.9, float(fromy)+0.1, (float)px+0.9, (float)py+0.1, float(level)*50.0);
      if (b) b = checkline((float)fromx+0.9, (float)fromy+0.9, (float)px+0.9, (float)py+0.9, float(level)*50.0);
      if (b) b = checkline((float)fromx+0.1, (float)fromy+0.9, (float)px+0.1, (float)py+0.9, float(level)*50.0);
    }

    // mark as visible
    if (b) v[px][py] = true;
  }

  void isovistLevel(int level, boolean[][] v, int x, int y, int a) {
    for (int px = x-level; px <= x+level; px++) {
      if (a != 0 || omnidirectional) addvisible(x, y, px, y-level, level, v, a); // top row
      if (abs(a) != 180 || omnidirectional) addvisible(x, y, px, y+level, level, v, a); // bottom row
    }

    // py < ynow+level and not '<=' otherwise diagonals are observed twice
    for (int py = y-level; py < y+level; py++) {
      if (a != 90 || omnidirectional)  addvisible(x, y, x+level, py, level, v, a);  // right row
      if (a != -90 || omnidirectional) addvisible(x, y, x-level, py, level, v, a);  // left row
    }
  }

  void checkIsovist(Solver pom) {    

    boolean[][] visible = isovist(xnow, ynow, angle);

    for (int j = 0; j < worldh; j++) {
      for (int i = 0; i < worldw; i++) {
        if (visible[i][j]) pom.observe(i, j);
      }
    }
  }

  boolean[][] isovist(int x, int y, int a) {
    boolean[][] vis = new boolean[worldw][worldh];

    for (int j = 0; j < worldh; j++) {
      for (int i = 0; i < worldw; i++) {
        vis[i][j]=false;
      }
    }

    for (int i = visibleLevels; i > 0; i--) {
      isovistLevel(i, vis, x, y, a);
    }
    return vis;
  }

  void checkVisualField(Solver pom) {

    if (filedofvision  > 0) {
      int x = xnow;
      int f = filedofvision;

      // the agent looks straight as far as a wall or the end of the world

      // if he is not facing right... 
      // in other words making sure that the agent can not see behind him, remove this checks if he is direction insensetive
      if (angle != -90) {
        while (x >=0 && f >=0) {
          x--;
          if (!exists(x, ynow)) {
            x++; 
            break;
          }            
          if ( wall(x, ynow)) break;
          if ( goal(x, ynow)) break;
          f--;
        }

        while (x <= xnow-1) {  
          pom.observe(x, ynow);
          x++;
        }
      }
      x = xnow; 
      f = filedofvision; 

      // if he is not facing left
      if (angle != 90) {
        while (x <= worldw-1 && f >=0) {
          x++;
          if (!exists(x, ynow)) {
            x--; 
            break;
          }
          if ( wall(x, ynow)) break;
          if ( goal(x, ynow)) break;
          f--;
        }

        while (x >= xnow+1) {
          pom.observe(x, ynow);
          x--;
        }
      }

      f = filedofvision; 
      int y = ynow;

      if (abs(angle) != 180) {
        while (y <= worldh-1 && f >=0) {
          y++; 
          if (!exists(xnow, y)) {
            y--; 
            break;
          }            
          if ( wall(xnow, y)) break;
          if ( goal(xnow, y)) break;
          f--;
        }

        while (y >= ynow+1) {
          pom.observe(xnow, y);
          y--;
        }
      }

      f = filedofvision; 
      y = ynow;

      if (angle != 0) {
        while (y >=0 && f >=0) {
          y--; 
          if (!exists(xnow, y)) {
            y++; 
            break;
          }
          if ( wall(xnow, y)) break;
          if ( goal(xnow, y)) break;
          f--;
        }

        while (y <= ynow-1) {
          pom.observe(xnow, y);
          y++;
        }
      }
    }
  }

  boolean isgoal(int x, int y) {
    if (exists(x, y) && goal(x, y) ) return true;
    return false;
  }

  void setGoalState (int x, int y) {
    GoalReached = true;
    gridworld[x][y] = S_Goalreached;
    gc.moving = false;
    dx=0;
    dy=0;
  }

  // true if at goal state
  boolean endstate() {
    if (GoalReached) return true;

    if (!orientwhenmoving) {
      if (isgoal(xnow - 1, ynow)) {
        setGoalState(xnow - 1, ynow);
      } else if (isgoal(xnow, ynow-1)) {
        setGoalState(xnow, ynow-1);
      } else if (isgoal(xnow, ynow+1)) {
        setGoalState(xnow, ynow+1);
      } else if (isgoal(xnow+1, ynow)) {
        setGoalState(xnow+1, ynow);
      }
    } else {
      // is a landmark right in front of him ? 
      if (angle==90 && isgoal(xnow - 1, ynow)) {
        setGoalState(xnow - 1, ynow);
      } else if (abs(angle)==180 && isgoal(xnow, ynow-1)) {
        setGoalState(xnow, ynow-1);
      } else if (angle==0 && isgoal(xnow, ynow+1)) {
        setGoalState(xnow, ynow+1);
      } else if ((angle==-90 || angle==270) && isgoal(xnow+1, ynow)) {
        setGoalState(xnow+1, ynow);
      }
    }

    return GoalReached;
  }

  void update(Solver pom) {

    if (GoalReached) return; //
    if (gc.animationDone()) {   // done movement animation, select the next step

      cell c = new cell(0, 0);


        if (posInPath < loaded_path_length) {

          if (pom != null) {
            pom.initObserve();
            pom.observe(xnow, ynow);
            checkIsovist(pom);
          }

          // if it is a rotation
          if (motorplan[posInPath].anglefrom != motorplan[posInPath].angleto) {
            setTargetAngle(motorplan[posInPath].anglefrom, motorplan[posInPath].angleto);
          } else {
            c = motorplan[posInPath];
          }
          posInPath++;
        } else {
          GoalReached = true;
        }
      

      // set the next step
      if ((c.x != 0 || c.y != 0) && !wall(xnow + c.x, ynow+c.y) && exists(xnow + c.x, ynow+c.y))  {
        setTargetXYat(c);
      } else {
      //  println("Bad move attempted, nothing happens.");
      }
    }  

    // if animation in progress
    if (gc.rotating) {

      // if done rotating 
      if (gc.donerotating(newangle)) {
        int newa = angle+newangle;//(angle+gc.da)%360;
        recordTurn(angle, newa);

        angle = newa; //(angle+gc.da)%360;
        gc.da = 0;
      }
    } else {

      // done moving
      if (gc.moving) {
        if (gc.donemoving(dx, dy)) {
          recordMove(xnow, ynow, xnow+dx, ynow+dy);
          xnow += dx; 
          ynow += dy;
          gc.moving = false;
        }
      }
    }
  }
}
