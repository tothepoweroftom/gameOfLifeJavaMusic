/*
      THOMAS POWER - Question 4 - Assignment 2
 Minim + ControlP5 integration.
 */

//Game of life sequencer based on RUIN & WESEN tutorial && inspired by Newscool in Reaktor
//https://vimeo.com/1824904?pg=embed&sec=1824904
//https://www.youtube.com/watch?v=5u5vBAMcLUE

/* --- RULES ---
 - Any live cell with fewer than two live neighbours dies, as if caused by under-population.
 - Any live cell with two or three live neighbours lives on to the next generation.
 - Any live cell with more than three live neighbours dies, as if by over-population.
 - Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
 */



import controlP5.*;

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;


//Setup cell grid parameters
int X_CELLS = 32;
int Y_CELLS = 32;
int CELL_SIZE = 12;


//Each cell either alive or dead use boolean value for cells
boolean cells[][] = new boolean[X_CELLS][Y_CELLS];
//Controls the tempo
int beatsPerSecond = 4;
int fps = 0;
boolean gameStarted = false;

float[] scale = {466,554,622, 739,830,932,1108,1244};

//AUDIO STUFF
Minim minim;
//Sampler samples[];
AudioOutput out;
Oscil wave;
MoogFilter moog;
float volume = 1.0;
float frequency = 20000.0;
float resonance = 0.0;



//UI 
ControlP5 cp5;
color col = color(255, 0, 0);
Slider vol;
Knob myKnobA;
Knob myKnobB;
Knob myKnobC;


void setup() {

  size(X_CELLS*CELL_SIZE + 200, Y_CELLS*CELL_SIZE + 100);

  //Initialize our cells
  for (int x = 0; x < X_CELLS; x++) {
    for (int y = 0; y < Y_CELLS; y++) {
      cells[x][y] = false;
    }
  }
  frameRate(25);

  //Initialize Audio
  minim = new Minim(this);
//  samples = new Sampler[8];
   // create a sine wave Oscil, set to 440 Hz, at 0.5 amplitude
  wave = new Oscil( 440, 0.0, Waves.SINE );
  // patch the Oscil to the output
    out = minim.getLineOut();
  wave.patch( out );
  moog    = new MoogFilter( frequency, resonance );

//  //Load up the samples
//  for (int i=0; i<8; i++) {
//    String name = str(i) + ".wav";
//    println(name);
//    samples[i] = new Sampler(name, 1, minim);
//    samples[i].patch( moog ).patch(out);
//  }


  //Initialize UI

  //Volume
  cp5 = new ControlP5(this);
  cp5.addSlider("volume")
    .setPosition(width-150, 20)
      .setRange(-60, 0)
        .setSize(20, 100)
          ;

  //Tempo
  cp5.addNumberbox("tempo")
    .setRange(1, 24)
      .setSize(100, 20)
        .setValue(12)
          .setMultiplier(0.1) // set the sensitifity of the numberbox
            .setPosition(width-150, 260)
              ;

  //Moog frequency
  myKnobB = cp5.addKnob("frequency")
    .setRange(50.0, 20000.0)
      .setValue(20000.0)
        .setPosition(width-150, 150)
          .setRadius(20)
            .setDragDirection(Knob.VERTICAL)
              ;

  //Moog resonance
  myKnobC = cp5.addKnob("resonance")
    .setRange(0.0, 1.0)
      .setValue(0.0)
        .setPosition(width-75, 150)
          .setRadius(20)
            .setDragDirection(Knob.VERTICAL)
              ;

  //Clear screen
  cp5.addButton("clear")
    .setValue(0)
      .setPosition(50, height-50)
        .setSize(50, 19)
          ;

  //Change to band pass
  cp5.addButton("BPFilter")
    .setValue(0)
      .setPosition(100, height-50)
        .setSize(50, 19)
          ;

  //Change to high pass
  cp5.addButton("HPFilter")
    .setValue(0)
      .setPosition(150, height-50)
        .setSize(50, 19)
          ;
  //Change to low pass
  cp5.addButton("LPFilter")
    .setValue(0)
      .setPosition(200, height-50)
        .setSize(50, 19)
          ;
  //Toggle play
  cp5.addToggle("play")
    .setPosition(width-80, height-50)
      .setSize(50, 30)
        .setValue(false)
          .setMode(ControlP5.SWITCH)
            ;
}


//Draws the cell at location x, y
void drawCell(int x, int y) {

  if (cells[x][y]) {
    fill(255);
    stroke(8);
    rect(x*CELL_SIZE + 1, y * CELL_SIZE + 1, CELL_SIZE, CELL_SIZE);
  }
}

//This functions counts the number of neighbours to apply the rules of life
int cellNeighbours(int x, int y) {
  int result = 0;
  for (int i = -1; i<=1; i++) {
    for (int j = -1; j<=1; j++) {
      int newX = x+ i;
      int newY = y + j;

      //Don't count itself
      if ( newX == x && newY == y) {
        continue;
      }

      if (newX >= 0 && newY >= 0 && newX < X_CELLS && newY < Y_CELLS) {

        //Count the contribution of neighbouring live cells
        if ( cells[newX][newY]) {
          result++;
        }
      }
    }
  }
  //Return number of neighbours
  return result;
}


//The mechanics of moving through the grid and applying the rules
void updateGameOfLife() {

  //Need a fresh 2D array to store the changes and apply them.
  boolean newCells[][] = new boolean[X_CELLS][Y_CELLS];
  for (int x = 0; x < X_CELLS; x++) {
    for (int y = 0; y< Y_CELLS; y++) {


      //Calculate number of neighbours using the function
      int neighbours = cellNeighbours(x, y);

      //Copy our grid
      newCells[x][y] = cells[x][y];

      //Die. Die. Live.
      if (neighbours<2) {
        newCells[x][y] = false;
      } else if (neighbours > 3) {
        newCells[x][y] = false;
      } else if (neighbours == 3 && !cells[x][y]) {
        newCells[x][y] = true;
        //CREATED NEW CELL
        //This will output an event!
        outputCell(x, y);
        println(cellValue(x, y));
//        samples[cellValue(x, y)].trigger();
        wave.setFrequency(scale[cellValue(x,y)]);
      }
    }
  }
  cells = newCells;
}

//REDUNDANT 
void outputCell(int x, int y) {
  // println(cellValue(x, y));
  //    if (cellValue(x,y) == '0'){
  //    samples[0].trigger();
  //  }
  //  switch (cellValue(x, y)) {
  //  case '0':
  //    samples[0].trigger();
  //    println("Called 0");
  //    break;
  //  case '1':
  //    samples[1].trigger();
  //    break;
  //  case '2':
  //    samples[2].trigger();
  //    break;
  //  case '3':
  //    samples[3].trigger();
  //    break;
  //  case '4':
  //    samples[4].trigger();
  //    break;
  //  case '5':
  //    samples[5].trigger();
  //    break;
  //  case '6': 
  //    samples[6].trigger();
  //  case '7':
  //    samples[7].trigger();
  //    break;
  //  default:
  //    break;
  //  }
}

//Number of different values accross the grid
int NUM_VALUES = 8;

int valueColors[] = new int[] {
  color(255, 0, 0), color(0, 255, 0), color(0, 0, 255), color(255, 255, 0), 
  color(0, 255, 255), color( 255, 0, 255), color(255), color(127)
};



//number 1-8 for each cell on grid
int cellValue(int x, int y) {
  return (x+y) % NUM_VALUES;
}

//Moves the game forward
void beat() {
  updateGameOfLife();
}


int currentCellX = -1;
int currentCellY = -1;
boolean currentDrawMode = false;


void keyPressed() {
  if (key == ' ') {
    gameStarted = !gameStarted;
    if(gameStarted){
      wave.setAmplitude(0.5);
    } else { 
      wave.setAmplitude(0);
    }
  }
  if (key == 'c' || key == 'C') {
    for (int x = 0; x < X_CELLS; x++) {
      for (int y = 0; y < Y_CELLS; y++) {
        cells[x][y] = false;
      }
    }
  }

  if ( key == '1' ) moog.type = MoogFilter.Type.LP;
  if ( key == '2' ) moog.type = MoogFilter.Type.HP;
  if ( key == '3' ) moog.type = MoogFilter.Type.BP;
}



void draw() {
  if (gameStarted) {
    fps++;
    if (fps > (frameRate / beatsPerSecond)) {
      beat();
      fps = 0;
    }
  }

  background(0);
  fill(0);
  stroke(255);
  rect(0, 0, CELL_SIZE * X_CELLS + 2, CELL_SIZE*Y_CELLS + 2);

  //GOL USER INTERFACE CODE

  //Draw new cells when grid is clicked on
  //Turn cell on if currently off and vice versa
  if (mousePressed) {

    int x = floor((float)(mouseX - 1) / (float)CELL_SIZE);
    int y = floor((float)(mouseY - 1) / (float)CELL_SIZE);

    if (x< X_CELLS && y < Y_CELLS) {
      if ( currentCellX != x || currentCellY != y) {
        if (currentCellX == -1) {
          if ( cells[x][y] ) {
            currentDrawMode = false;
          } else {
            currentDrawMode = true;
          }
        }
        cells[x][y] = currentDrawMode;
        currentCellX = x;
        currentCellY = y;
      }
    }
  } else {
    currentCellX = -1;
    currentCellY = -1;
  }

  //Colored rectangles for values
  for (int x = 0; x < X_CELLS; x++) {
    for (int y = 0; y < Y_CELLS; y++) {

      color c = valueColors[cellValue(x, y)];
      fill(c);
      stroke(c);
      rect(x*CELL_SIZE + 1 + CELL_SIZE/2, 
      y*CELL_SIZE + 1 + CELL_SIZE/2, 1, 1); 
      drawCell(x, y);
    }
  }
}

//Clear all samples from memory and stop engine
void stop() {


  for (int i=0; i<8; i++) {

//    samples[i].stop();
  }
  minim.stop();
}



//UI Functions----------
void volume(float _volume) {

  out.setGain(_volume);

  println("The Volume has been set to " + _volume + " dB");
}

void tempo(int _tempo) {

  beatsPerSecond = _tempo;
}

void resonance(float _resonance) {
  moog.resonance.setLastValue( _resonance );
}

void frequency(float _frequency) {
  moog.frequency.setLastValue( _frequency );
}

void clear() {
  for (int x = 0; x < X_CELLS; x++) {
    for (int y = 0; y < Y_CELLS; y++) {
      cells[x][y] = false;
    }
  }
}

void HPFilter() {
  moog.type = MoogFilter.Type.HP;
}

void LPFilter() {
  moog.type = MoogFilter.Type.LP;
}

void BPFilter() {
  moog.type = MoogFilter.Type.BP;
}

void play(boolean flag) {
  if (flag) {
    gameStarted = true;
  } else {
    gameStarted = false;
  }
}

