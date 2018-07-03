// ----------------------------------- a simple struct to encode the position of the agent on the grid ------------------------

class cell { 
  
  int x, y;
  int angleto, anglefrom;

  float prob;
  float value;
  boolean moveExists;
    
  cell(int i, int j) {
    x=i;
    y=j;
    prob = 0;
    value=0;
    moveExists = false;
  }

  cell(int i, int j, float v, boolean exists) {
    x=i; 
    y=j;
    prob = 0;
    value=v;
    moveExists = exists;
  }
  
  cell(int i, int j, float v, float p, boolean exists) {
    x=i; 
    y=j;
    prob = p;
    value=v;
    moveExists = exists;
  }

  String getActionName() {
    if (x==-1 && y==0) return "left";
    if (x==1 && y==0) return "right";
    if (y==-1 && x==0) return "up";
    if (y==1 && x==0) return "down";
    return "err:" + x + "," + y;
  }
}