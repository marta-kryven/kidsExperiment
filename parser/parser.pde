// this will read the files produced by PHP and write them into one better formatted file with all subjects 
//boolean comment_mode = false;

void setup() {
  PrintWriter planwriter = null;
  PrintWriter attribwriter = null;  
  planwriter = createWriter("parsedPlan.csv");
  attribwriter = createWriter("parsedAttrib.csv");
  
  String[] list = null;
  String sdir = "/Users/luckyfish/Desktop/processing/ExperimentKids/allKidsPilot/";
  
  // get all files in a directory
  File dir = new File(sdir);
  list = dir.list();
  if (list == null) {
    println("Folder does not exist or cannot be accessed.");
  } else {

      planwriter.println("subject\tage\tgender\tdate\ttime\tbrowser\tip\tmaze\tsteps\trevisits\tpath\ttimes");
      planwriter.flush();
      attribwriter.println("subject\tage\tgender\tdate\ttime\tbrowser\tip\ttrial\twhichpirate\ttime");
      attribwriter.flush();
    
    for (int i = 0; i < list.length; i++) {
      
      if ( list[i].indexOf(".DS_Store") != -1) continue;
      if ( list[i].equals(".txt")) continue;
       
      // process one file
      String[] tok = splitTokens(list[i], ".");
   
      println("parsing:", list[i]);
      String sub = tok[0];
      String lines[] = loadStrings(sdir + list[i]);
      
      //println("parsing line:", lines[0]);
      String[] tokens = splitTokens(lines[0], " ");
      String ip = tokens[0];
      String date = tokens[1];
      String time = tokens[2];
      String browser = tokens[3];
      
      int g = lines[0].indexOf("Gender:");
      int a = lines[0].indexOf("Age:");
      String age = lines[0].substring(a + 4, g-1); age = age.trim();
      String gender = lines[0].substring(g+7); gender.trim();
      
      for (int j = 1; j < lines.length; j++) {

        if ( lines[j].indexOf("comment") != -1 || lines[j].indexOf("decision") != -1 ) continue;
        tokens = splitTokens(lines[j], " ");
        if (tokens.length < 5) { println("bad line:", lines[j]); continue; }
        
        ip = tokens[0];
        date = tokens[1];
        time = tokens[2];
        browser = tokens[3];
        String subject = tokens[4];  
        boolean video = false;
        String times;
          
        if (lines[j].indexOf(".mp4") != -1) {
            video = true;
            attribwriter.print(subject + "\t");
            attribwriter.print(age + "\t");
            attribwriter.print(gender + "\t");
            attribwriter.print(date.trim() + "\t");
            attribwriter.print(time.trim() + "\t");
            attribwriter.print(browser.trim() + "\t");
            attribwriter.print(ip.trim() + "\t");
            
            String name1 = tokens[6];
            String name2 = tokens[7];
            attribwriter.print(name1.trim() + "," + name2.trim() + "\t");
            times = tokens[8];
            
       } else {
            
            String name = tokens[5];
            if (name.indexOf("practice") != -1) continue;
            int idx = 0;
            if (name.indexOf("easy") != -1) idx = name.indexOf("easy");
            if (name.indexOf("medium") != -1) idx = name.indexOf("medium");
            if (name.indexOf("hard") != -1) idx = name.indexOf("hard");
            
            planwriter.print(subject + "\t");
            planwriter.print(age + "\t");
            planwriter.print(gender + "\t");
            planwriter.print(date.trim() + "\t");
            planwriter.print(time.trim() + "\t");
            planwriter.print(browser.trim() + "\t");
            planwriter.print(ip.trim() + "\t");
            planwriter.print(name.substring(idx).trim() + "\t");
            
            println(name.substring(idx).trim());
            
            String path = tokens[7];
            path = path.trim();
          
            // steps
            tok = splitTokens(path, "p");
            planwriter.print(tok.length + "\t");
            
            // revisits
            int revisits = 0; 
            for (int k = 0; k < tok.length; k++) {
              // if this token is not among the previous
              boolean no = true;
              for (int l = 0; l < k; l++) {
                 if (tok[k].indexOf(tok[l]) != -1) {
                   no = false;
                   break;
                 }
              }
               
              if (no) {
                 for (int l = k+1; l < tok.length; l++) {
                   if (tok[k].indexOf(tok[l]) != -1) {
                     revisits++;
                     break;
                   }
                }
              }
            }
            
            planwriter.print(revisits + "\t");
            
            // path
            planwriter.print(path + "\t");
            
            times = tokens[8];
          }

          // preprocess times into ms. per step
          // t(14,35,23,371);t(14,35,24,445);t(14,35,25,270);t(14,35,25,898);t(14,35,26,633);t(14,35,30,647);t(14,35,31,180);t(14,35,31,949);t(14,35,32,495);
          //writer.print(times);
          
          tok = splitTokens(times, ";");
          long t1=0;
          String timesMS = "";
          
          for (int t = 0; t < tok.length; t++) {
            String[] tt = splitTokens(tok[t].substring(2, tok[t].length()-1), ",");
            if (t1 == 0) {
              // initialisie t1
              t1 = Integer.parseInt(tt[1])*60*1000 + Integer.parseInt(tt[2])*1000 + Integer.parseInt(tt[3]);
            } else {
              // record the difference
              long t2 = Integer.parseInt(tt[1])*60*1000 + Integer.parseInt(tt[2])*1000 + Integer.parseInt(tt[3]);
              long diff = t2-t1;
              t1 = t2;
              timesMS += (diff + ";");
            }
          }
          
          if (!video) {
            planwriter.print(timesMS.trim());
            planwriter.println();
          } else {
            attribwriter.print(tokens[9]+"\t");
            attribwriter.print(timesMS.trim());
            attribwriter.println();
          }
        
      }
    }
    
  } 
  
  attribwriter.flush();
  planwriter.flush();
}

void draw() {
}
