import java.nio.file.Path;
import java.nio.file.Paths;
import com.hamoid.*;
VideoExport videoExport = null;

// -----------------------------------------------------------------------------------------------------------------
//
//        grid cell states when reading maps
//
// -----------------------------------------------------------------------------------------------------------------

final int S_landmark = 2; // an unvisited goal
final int S_wall = 3;     // a wall
final int S_Goalreached = 4; // a visited goal
final int S_AgentStartingPosition = 5; // a visited goal

// -----------------------------------------------------------------------------------------------------------------
//
//        movies are described in this file
//
// -----------------------------------------------------------------------------------------------------------------


String movieListFile = "auto_movie_generation.csv"; 
String mapDir = "mazes/";
// -----------------------------------------------------------------------------------------------------------------
//
//       texture images 
//
// -----------------------------------------------------------------------------------------------------------------

String startingcelltex =  "door.png";     // image of the starting cell from which the agentstarts
String goalcelltex = "goalimg.jpeg";
String[] agentImages = {"agentg.png", "agentc.png", "agentd.png", "agente.png", "agentf.png", "agenth.png"};
PImage floorimg, wallimg, Ximg, agentimg, goalimg; 
String floortex = "";      
String walltex =   ""; 
String agenttex = "agent.png";
boolean textured = true;     // switches the textures on or off; 

// -----------------------------------------------------------------------------------------------------------------
//
//       rendering parameters
//
// -----------------------------------------------------------------------------------------------------------------


final int off = 10;       // rendering; leaves a border between the side of the screen and the  grid
final int cellsize = 80; //100; // rendering; size of a grid cell in pixels
int vRotation = 3; // rotation velocity            
float vm = 3; // movement velocity
boolean renderflipped = false;   // vertical orientation
boolean recording = false; // true if rendering frames to file
AgentGraphics gc = new AgentGraphics();

boolean omnidirectional = true; // 360 degree vision

String agentPathString = "";
cell[] agent_path = {};
int loaded_path_length = 0;
int agent_pathpos = 0;
int worldw = 10;
int worldh = 8;
int[][] gridworld = new int[worldw][worldh]; // the map of the world
gridWorld world; // maze generator based on Prim's algorithm


// ---------------------------- agent behaviour --------------------------------------------------------------------

AgentState agent;       // agent controller
boolean orientwhenmoving = false; // the agent orients toward direction of motion
int filedofvision = 50; // how many cells can he see in a straight line? 50 means essentilaly unlimited
int visibleLevels = 10; // how far can he see using isovist vision?

Solver observationModel = null;
String currentWorldMap = ""; 
int nextmovie = 1;
String[] automovie = null;
String movieName = ""; 
boolean renderingMovie = false;
boolean firstframe = true;

int agent_start_x = 0;    // where whould the initial location be
int agent_start_y = 0;

void setup() {
  //size(980, 350); // tradeoff2
  // size(900, 350); // tradeoff3
 // size(580, 350); // tradeoff4, 5
 // size(500, 350); // tradeoff1
   // size(740, 350); // bigsmall
   // size(980, 350); // tradeoff7
  //size(900, 350); // farclose
   size(980, 400); 
  
  
  gc.setupGC();
  agent = new AgentState(agent_start_x, agent_start_y, 0); // create the agent 
  agent.resetAgent();
  agent.resetAgentPos(agent_start_x, agent_start_y);

  frameRate(60); 
  automovie = loadStrings(movieListFile);
  observationModel = new Solver();
}

// ----------------------------------------  main loop ---------------------------

void draw() {

  background(255);

  if (!textured) gc.drawGrid();  
  gc.drawWorld();
  
  doAutomovie();
  
  gc.drawAgent(agent.xnow, agent.ynow, agent.angle);
  agent.update(observationModel); 
  
  if (recording) {

      if (firstframe) {
        firstframe = false;
      } else {
        if (videoExport == null) {
          videoExport = new VideoExport(this, "moviedir/" + movieName + ".mp4"); 
          videoExport.setFrameRate(40);
        }
        videoExport.saveFrame();
        if (gc.moving == false) {
          for (int i=1; i <= 5; i++) videoExport.saveFrame();
        }
      }
  }
}

void doAutomovie() {
  if (!renderingMovie) {
    
    if (nextmovie < automovie.length) {                                      // load the next movie
      String   movie = automovie[nextmovie];
      println("loading the next movie: ", movie);

      if ( movie!= null && movie.length() > 1) {
        String[] line = split(movie, '\t');
        int skip = int(trim(line[4]));
        println ("generating...", nextmovie, "skip: ", line[4], ", ", skip );   // some movies are skipped

        if ( skip != 1 ) {
          currentWorldMap = trim(line[1]);
          movieName = currentWorldMap;
          currentWorldMap += ".txt";
          currentWorldMap = mapDir  + currentWorldMap;
          renderflipped = ( int(trim(line[5])) > 0);                          // some movies are flipped
          readWorld(currentWorldMap);

          String s = trim(line[3]);
          if (s.length() > 4) {
            println("floor texture:", s);
            floortex = s;
          } else {
            floortex = "";
          }

          s = trim(line[2]);
          if (s.length() > 4) {
            walltex = s;
            println("wall texture:", s);
          }

          agenttex = agentImages[int(random(agentImages.length))];
          gc.setupGC();
          
          movieName = trim(line[0]);
          String moviename =  "moviedir/" + movieName + ".mp4";
          videoExport = new VideoExport(this, moviename); 
          videoExport.setFrameRate(40);
          agentPathString = line[7];

          if (agentPathString.length() > 2) {
            loadPath();
          } 

          observationModel.reset();
          recording = true;
          firstframe = true;
          renderingMovie = true;
        }
      }
      nextmovie++;
    } else {
      //println("Done rendering movies");
    }
  } else {
   boolean finished = agent.GoalReached;
    if ( finished ) {
      recording = false;
      observationModel.reset();
      agent.resetAgent();
      agent.resetAgentPos(agent_start_x, agent_start_y);
      renderingMovie = false;
      println("Finished rendering... ");
    }
  }
}


void readWorld(String w) {
  // println("reading world: ", w);
  String world[] = loadStrings(w);

  if (renderflipped) {
    println("rendering flipped");
    worldh = int(trim(world[0]));  
    worldw = int(trim(world[1]));
  } else {
    worldh = int(trim(world[1]));  
    worldw = int(trim(world[0]));
  }

  println("world: ", worldw, worldh);
  gridworld = new int[worldw][worldh];

  for (int i=2; i<world.length; i++) {

    String s = world[i];
    for (int j = 0; j < s.length(); j++) {
      int cell = int(s.substring(j, j+1));

      if (cell == S_AgentStartingPosition) {   // codes for the agent's starting position
        agent.xnow = j; 
        agent.ynow = i-2;
        gridworld[j][i-2] = 0;
        agent_start_x = j;
        agent_start_y = i-2;
        agent.resetAgent();
        agent.resetAgentPos(agent_start_x, agent_start_y);
      } else {
        if (renderflipped) {
          gridworld[i-2][j] = cell;
        } else {
          gridworld[j][i-2] = cell;
        }
      }
    }
  }
}

void parsePathFromString(String inferencepath) {
  String[] spath = split(inferencepath, ';');
  agent_path = new cell[spath.length-1];
  loaded_path_length = 0;
  for (int i = 0; i < spath.length-1; i++) {

    String op = spath[i].substring(0, 1); 

    // next element
    if (op.equals("r")) { 
      // rotation
      cell c = new cell(0, 0);
      int comma = spath[i].indexOf(",", 1);
      String temp = spath[i].substring(2, comma);
      int a1 = int(temp); 
      int end = spath[i].indexOf(")", comma);
      int a2 = int(spath[i].substring(comma+1, end)); 
      if (a2 == 270) a2 = -90;
      if (a1 == 270) a1 = -90;
      if (a2 == -270) a2 = 90;
      if (a1 == -270) a1 = 90;
      
      c.angleto = a2;
      c.anglefrom = a1;
   //   println (i, ": r(", a1, ",", a2, ")");
      if (renderflipped) {

        if (c.anglefrom == -90) {
          c.anglefrom = 0;
        } else if (abs(c.anglefrom) == 180) {
          c.anglefrom = 90;
        } else if (c.anglefrom == 90 && c.angleto == 180) {
          c.anglefrom = 180;
        } else if (c.anglefrom == 90 && c.angleto == -90) {
          c.anglefrom = 180;
        } else {
          c.anglefrom = c.anglefrom-90;
        }
        
        if (c.angleto == -90)   {
          c.angleto = 0;
        } else if (abs(c.angleto) == 180){
          c.angleto = 90;
        } else if (c.angleto == 90) {
          if (c.anglefrom == -90) {
            c.angleto = -180;
          } else {
            c.angleto = 180;
          }
        } else {
          c.angleto = c.angleto-90;
        }
   //     println (i, ": flipped r(", c.anglefrom, ",", c.angleto, ")");
      }
      
      
      agent_path[loaded_path_length] = c;
      loaded_path_length++;
    } else if (op.equals("p")) {
      // position
      int comma = spath[i].indexOf(",", 1);
      int x = int(spath[i].substring(2, comma)); 
      int end = spath[i].indexOf(")", comma);
      int y = int(spath[i].substring(comma+1, end)); 

      cell c;
      if (renderflipped) {
        c = new cell(y, x);
      } else {
        c = new cell(x, y);
      }
      agent_path[loaded_path_length] = c;
      loaded_path_length++;
    }
  }  

  // convert to a (dx, dy) format
  agent_pathpos = loaded_path_length-1;
  while (agent_pathpos >= 1) {
    cell c = agent_path[agent_pathpos];
    cell pc = agent_path[agent_pathpos-1];
    int x = c.x, y = c.y, px = pc.x, py = pc.y;

    boolean update = true;
    if (x == 0 && y == 0 && agent_pathpos!=0 && ( c.angleto !=0 || c.anglefrom !=0 )) {
      // this step is a roatation, no change
      update = false;
    } else if (px == 0 && py == 0 && ( pc.angleto !=0 || pc.anglefrom !=0 )) {
      // previous step was a rotation, look up one more cell back
      if (agent_pathpos-2 >= 0) {
        pc = agent_path[agent_pathpos-2]; 
        px = pc.x; 
        py = pc.y;
      } else {
        // reached the end
        update=false;
      }
    } 

    if (update) {
      println("dx:", x-px, "dy:", y-py );
      if (x-px==-1) {
        agent_path[agent_pathpos].x = -1;
        agent_path[agent_pathpos].y = 0;
      } else if (y-py==1) {
        agent_path[agent_pathpos].x = 0;
        agent_path[agent_pathpos].y = 1;
      } else if (y-py==-1) {
        agent_path[agent_pathpos].x = 0;
        agent_path[agent_pathpos].y = -1;
      } else if (x-px==1) {
        agent_path[agent_pathpos].x = 1;
        agent_path[agent_pathpos].y = 0;
      } else {
        println("ERR: ", x, ",", y);
      }
    }
    agent_pathpos--;
  }

  agent_pathpos=0;
  agent_path[0].x=0;
  agent_path[0].y=0;
}

void loadPath() {
  observationModel.reset();
  agent.resetAgent();
  agent.resetAgentPos(agent_start_x, agent_start_y);
  if (renderflipped) {
    agent.angle = -90;
  }
  parsePathFromString(agentPathString);
  agent.setMotorplan(agent_path);
}

// ---------------------------------------------------------------------- Misc ----------------------------------

boolean exists(int x, int y) {
  if (x >= 0 && x < worldw && y >= 0 && y < worldh ) {
    return true;
  }

  return false;
}

boolean wall(int x, int y) {
  if (!exists(x, y)) {
    //println("called wall() for a bad cell", x, ",", y);
    return true;
  }

  return (gridworld[x][y] == S_wall);
}

boolean goal(int x, int y) {
  if (!(exists(x, y))) return false;
  return (gridworld[x][y] == S_landmark);
}
