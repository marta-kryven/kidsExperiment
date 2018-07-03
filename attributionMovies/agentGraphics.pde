

class AgentGraphics {
  float offx, offy; // pixel offset in the current cell, which will be zero if the agent is located in the centre of the cell
  int da;

  boolean moving, rotating; // set to true while moving agent between cells

  AgentGraphics() {
    resetAgent();
  }

  void resetAgent() {
    da=0;
    offx = 0;
    offy = 0;
    moving = false;
    rotating = false;
  }

  void setupGC() {
    if (floortex.length() > 0) {
      floorimg = loadImage("textures/"+ floortex);
    } else {
      floorimg = null;
    }
    wallimg  = loadImage("textures/"+ walltex);
    agentimg  = loadImage("textures/"+ agenttex);
    Ximg  = loadImage("textures/"+ startingcelltex);
    
    surface.setResizable(true);
  }

  boolean donemoving(int dx, int dy) {
    if (renderDelay > 0) {
      return false;
    }
    
    if ( abs(offx) < cellsize && abs(offy) < cellsize ) {
      offx = dx*(abs(offx)+vm);
      offy = dy*(abs(offy)+vm);

      return false;
    } else {
      moving = false;

      offx = 0;
      offy = 0;

      return true;
    }
  }

  boolean donerotating (int newangle) {
    if (renderDelay > 0) {
      return false;
    }
    
    if (abs(newangle)-abs(da) >0) {
      da = newangle/abs(newangle)*(abs(da)+vRotation);
      return false;
    } else {
      rotating = false; 
      return true;
    }
  }

  boolean animationDone() {
    return (!moving && !rotating);
  }

  void drawAgent(int x, int y, int a) {

    pushMatrix();
    translate(off, off);
    translate(x*cellsize, y*cellsize);

    if ( renderDelay == 0 ) {

      if (moving && !rotating) {
        translate(offx, offy);
      } 

      pushMatrix();
      translate(cellsize/2, cellsize/2);
      if (orientwhenmoving) {
        if (rotating) {
          rotate((a+da)*PI/180.0);
        } else {
          rotate(a*PI/180.0);
        }
      }
      translate(-cellsize/2, -cellsize/2);
      image(agentimg, 0, 0, cellsize-2, cellsize-2);
      popMatrix();
    } else {
      translate(cellsize/2, cellsize/2);
      rotate(a*PI/180.0);
      translate(-cellsize/2, -cellsize/2);
      image(agentimg, 0, 0, cellsize-2, cellsize-2);
      renderDelay--;
    }

    popMatrix();
  }

  // draw world
  void drawGrid() {

    // outline
    stroke(255, 0, 0, 100); 
    strokeWeight(5);
    line(off, off, off+cellsize*worldw, off);
    line(off, off, off, off+cellsize*worldh);
    line(off+cellsize*worldw, off, off+cellsize*worldw, off+cellsize*worldh);
    line(off, off+cellsize*worldh, off+cellsize*worldw, off+cellsize*worldh);

    // gridcells
    stroke(0, 100); 
    strokeWeight(1);

    for (int i = off; i < off+cellsize*worldw; i += cellsize) {
      // vertical lines
      line(i, off, i, off+cellsize*worldh);
    }

    for (int i = off; i < off+cellsize*worldh; i += cellsize) {
      line(off, i, off+cellsize*worldw, i);
    }
  }

  void drawWorld() {
   
    for (int i = 0; i < worldw; i++) {
      for (int j = 0; j < worldh; j++) {

        pushMatrix();
        translate(off, off);
        translate(i*cellsize+1, j*cellsize+1);

        if (wall(i, j)) {
          fill(0, 255, 255, 150); 
          stroke(0, 255, 255, 100);
          if (!textured) {
            rect(0, 0, cellsize-2, cellsize-2);
          } else {
            image(wallimg, 0, 0, cellsize, cellsize);
          }
        } else {
          fill(255, 255, 255, 255); 
          stroke(0, 0, 0, 100);
          rect(0, 0, cellsize-1, cellsize-1);
          if (textured) {
            if (agent_start_x == i && agent_start_y == j) {
              image(Ximg, 2, 2, cellsize-4, cellsize-4);
            } else if (floorimg != null) {
              image(floorimg, 0, 0, cellsize, cellsize);
            }
          }
        }

        if (goal(i, j) || gridworld[i][j] == S_Goalreached ) {
          if (goal(i, j)) {
            fill(255, 0, 0); 
            stroke(255, 0, 0);
          } else {
            fill(255, 0, 255); 
            stroke(255, 0, 255);
          }

          pushMatrix();
          translate(cellsize/2, cellsize/2);
          ellipse(0, 0, cellsize-2, cellsize-2);
          popMatrix();
        }

        // does the agent know about this cell?  we do not show how much does he know, only that he does know
          if (observationModel != null) {
            if (!observationModel.hasobserved(i, j)) {
              stroke(0, 220);
              fill(0, 255);
              rect(0, 0, cellsize, cellsize);
            }
          }
        popMatrix();
      }
    }
  }
}