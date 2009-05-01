
/**
 * Based on code from the example code for the Memsic2125 in the Arduino examples and the
 * LED matrix serial controller example code from Sparkfun:
 *    http://www.sparkfun.com/commerce/product_info.php?products_id=760
 **/

// Pins
#define XPIN 2
#define YPIN 3

#define DATAOUT 11//MOSI
#define DATAIN  12//MISO 
#define SPICLOCK  13//sck
#define SLAVESELECT 10//ss

//Define the "Normal" Colors
#define BLACK  0
#define RED  0xE0
#define GREEN  0x1C
#define BLUE  0x03
#define ORANGE  RED|GREEN
#define MAGENTA  RED|BLUE
#define TEAL  BLUE|GREEN
#define WHITE (RED|GREEN|BLUE)-0xA0

#define UP 0
#define RIGHT 1
#define DOWN 2
#define LEFT 3

int pulseX, pulseY;
int accX, accY;
char color_buffer [64];
int current_loc=27;

void setup() {
  // Accelorometer Setup
  pinMode(XPIN, INPUT);
  pinMode(YPIN, INPUT);
  
  // LED Matrix Setup
  SPCR = (1<<SPE)|(1<<MSTR)|(1<<SPR1);	//Enable SPI HW, Master Mode, divide clock by 16
  pinMode(DATAOUT, OUTPUT);
  pinMode(DATAIN, INPUT);
  pinMode(SPICLOCK,OUTPUT);
  pinMode(SLAVESELECT,OUTPUT);
  digitalWrite(SLAVESELECT,HIGH);
  
  color_buffer[current_loc] = RED;
}

void loop() {
  pulseX = pulseIn(XPIN,HIGH);  
  pulseY = pulseIn(YPIN,HIGH);
  accX = ((pulseX / 10) - 500) * 8;
  accY = ((pulseY / 10) - 500) * 8;
  
  if(accX > 500)
    move(RIGHT);
  else if(accX < -500)
    move(LEFT);
  
  if(accY > 500)
    move(DOWN);
  else if(accY <= -500)
    move(UP);
  
  delay(200);
}

void move(int dir) {
  if(dir == RIGHT && (current_loc % 8) != 7) {
    reset_current();
    color_buffer[++current_loc] = RED;
    draw();
  } else if(dir == LEFT && (current_loc % 8) != 0) {
    reset_current();
    color_buffer[--current_loc] = RED;
    draw();
  } else if(dir == UP && current_loc < 56) {
    reset_current();
    current_loc += 8;
    color_buffer[current_loc] = RED;
    draw();
  } else if(dir == DOWN && current_loc > 7) {
    reset_current();
    current_loc -= 8;
    color_buffer[current_loc] = RED;
    draw();
  }
}

void clear_screen() {
  for(int i=0; i<64; i++) {
    color_buffer[i] = BLACK;
  }
  draw();
}
void reset_current() {
  color_buffer[current_loc] = BLACK;
}

void draw() {
  digitalWrite(SLAVESELECT, LOW);
  delay(10);
  for(int LED=0; LED<64; LED++){
    spi_transfer(color_buffer[LED]);
  }
  delay(10);
  digitalWrite(SLAVESELECT, HIGH);
}

//Use this command to send a single color value to the RGB matrix.
//NOTE: You must send 64 color values to the RGB matrix before it displays an image!
char spi_transfer(volatile char data) {
  SPDR = data;                      // Start the transmission
  while (!(SPSR & (1<<SPIF))) { };  // Wait for the end of the transmission
  return SPDR;                      // return the received byte
}
