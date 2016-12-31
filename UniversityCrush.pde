// score
int score = 0;
int maxscore = 1000;
float scoreHeight;
float scoreScale;
int coups = 0;
int coups_restants = 20;
int gameState = 0; // 0 - jeu en cours; 1 - win; 2 = loose;
PImage Winimage;
PImage Loseimage;
int seuil1 = maxscore/4;
int seuil2 = maxscore/2;
int seuil3 = 3*maxscore/4;
boolean seuil1_franchi = false;
boolean seuil2_franchi = false;
boolean seuil3_franchi = false;

int gridW, gridH;
int cellWidth, cellHeight;
int leftMargin, topMargin;

int cellCX, cellCY;
int cellDX, cellDY;

// tout ce qu'il faut pour piloter une animation
float propAnim      = 0.0; 
boolean animRunning = false;
int NONE            = 0;
int FALLING         = 1;
int LASER           = 2;
int HORI            = 3;
int VERT            = 4;
int SQBOOM          = 5;
int SQDBLBOOM       = 6;
int STARCROSS       = 7;
int BIGBONBON       = 8;
int ALLSTRIP        = 9;
int ALLSTRIP2       = 10;
int ALLSTRIP3       = 11;
int DOUBLELASER     = 12;
int SUPERLASER      = 13;
int accumulateurChute = 1;

int animType        = NONE;
int animCount       = 0;
int EMPTY           = -1;
// infos utiles pour afficher l'animation
int animi=-1, animj=-1;   // l'endroit ou on declenche l'animation
int animi2=-1, animj2=-1; // l'autre bonbon mitoyen qui a peut etre une influence sur l'animation

int maxElemTypes  = 5; // 5 types = rouge, vert, bleu, violet, jaune.
int maxAvailTypes = 5; // un niveau n'utilise pas toujours tous les types possibles
int maxBonusTypes = 5; // normale, rayee H, rayeeV, "en sachet", en boule choco

// liste des images avec toutes les versions bonus
PImage imgs[][] = new PImage [maxBonusTypes+1][maxElemTypes];
PImage bg;
PImage imgcase;


// noyau gaussien de rayon 2 .. pour les flous et les ombres
int[][] gKern = {
  {
    1, 4, 7, 4, 1
  }
  , {
    4, 16, 26, 16, 4
  }
  , {
    7, 26, 41, 26, 7
  }
  , {
    4, 16, 26, 16, 4
  }
  , {
    1, 4, 7, 4, 1
  }
};

// la grille de bonbons ... a detruire
int[][] grid; 

// la grille des decallages a appliquer (temporairement) a l'affichage bonbons
int[][] gridDec; 





void setupLevel1() {
  // on utilise tous les types de bonbons disponibles
  maxAvailTypes = maxElemTypes;

  for (int j=0; j<gridH; j++)
    for (int i=0; i<gridW; i++) {
      grid[j][i] = EMPTY;
      gridDec[j][i] = 0;
    }

  // remplissage aleatoire
  randomSeed(2);
  for (int j=0; j<gridH; j++)
    for (int i=0; i<gridW; i++) {
      do {
        grid[j][i] = int(random(0, maxAvailTypes));
      } 
      while (crushable (i, j));
    }

  grid[4][3] = 2;
   grid[5][2] = 2;
   grid[2][2] = 1+maxElemTypes*2;
   grid[2][3] = 1+maxElemTypes*4;  
   grid[2][4] = 1+maxElemTypes*4;
   grid[2][5] = 1+maxElemTypes*3;
}////////////////////////////


PImage creerVersionOmbree(PImage src) {
  PImage dst = createImage(src.width+4, src.height+4, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {

      float acc = 0;
      for (int dj=-2; dj<=2; dj++)
        for (int di=-2; di<=2; di++) 
          if ((i+di)>=0 && (i+di)<cellWidth && (j+dj)>=0 && (j+dj)<cellHeight)
            acc+=  gKern[dj+2][di+2]*alpha(src.pixels[(i+di)+(j+dj)*src.width]);
      acc = acc/273;
      dst.pixels[i+2+(j+2)*dst.width] = color(0, 0, 0, acc);
    }
  }

  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      if (alpha(src.pixels[(i)+(j)*src.width])>0)
        dst.pixels[i+2+(j+2)*dst.width] = src.pixels[(i)+(j)*src.width];
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionRayeeVertical(PImage src, int type) {
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red  (src.pixels[i+j*src.width]);
      float g = green(src.pixels[i+j*src.width]);
      float b = blue (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);

      // T2.2
      float sinus = sin(dist(-15, src.height/2, i, j)/1.5);
      dst.pixels[i+j*src.width] = color((3*r/4*abs(sinus) + (255-3*(255-r)/4)*(1-abs(sinus))), 
      (3*g/4*abs(sinus) + (255-3*(255-g)/4)*(1-abs(sinus))), 
      (3*b/4*abs(sinus) + (255-3*(255-b)/4)*(1-abs(sinus))), a); // rayures sombres
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionRayeeHorizontal(PImage src, int type) {
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red  (src.pixels[i+j*src.width]);
      float g = green(src.pixels[i+j*src.width]);
      float b = blue (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);

      // T2.2
      float sinus = sin(dist(src.width/2, -15, i, j)/1.5);
      dst.pixels[i+j*src.width] = color((3*r/4*abs(sinus) + (255-3*(255-r)/4)*(1-abs(sinus))), 
      (3*g/4*abs(sinus) + (255-3*(255-g)/4)*(1-abs(sinus))), 
      (3*b/4*abs(sinus) + (255-3*(255-b)/4)*(1-abs(sinus))), a);
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionSachet(PImage src, int type) {
  println("");
  PImage dst = createImage(src.width, src.height, ARGB);
  dst.loadPixels();
  // color
  int col = src.pixels[src.width/2+src.height/3*src.width];
  //float rcol = red   (col)/2;
  //float gcol = green (col)/2;
  //float bcol = blue  (col)/2;
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float r = red   (src.pixels[i+j*src.width]);
      float g = green (src.pixels[i+j*src.width]);
      float b = blue  (src.pixels[i+j*src.width]);
      float a = alpha (src.pixels[i+j*src.width]);
      float i0 = i-cellWidth/2;
      float j0 = j-cellHeight/2;
      float j1 = j-2*cellHeight/3;
      // T2.5

      float dist = (3.5*(Math.max(Math.abs(i0), Math.abs(j0/1.2)))+sqrt(i0*i0+j0*j0))/2.0;
      if (dist < (float)cellWidth) {
        if (alpha(src.pixels[i+j*src.width]) > 0 && abs(i) < cellWidth) {
          dst.pixels[i+j*src.width] = color(cellWidth*r/(1.5*dist), cellWidth*g/(1.5*dist), cellWidth*b/(1.5*dist), a);
        } else {
          dst.pixels[i+j*src.width] = color(red(col), green(col), blue(col), 230);
        }
      }
    }
  }
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionChoco(PImage src, int type) {
  PImage dst = createImage(src.width, src.height, ARGB);
  int col = src.pixels[src.width/2+src.height/3*src.width];
  dst.loadPixels();
  for (int j=0; j<src.height; j++) {
    for (int i=0; i<src.width; i++) {
      float i0 = i-src.width/2;
      float j0 = j-src.height/2;
      float i1 = i-src.width/3;
      float j1 = j-src.height/3;

      float dist0 = sqrt(i0*i0+j0*j0);
      float dist1 = sqrt(i1*i1+j1*j1)/2.0;
      float dist2 = 0.8-(sqrt(i*i+j*j)/(src.width*src.height)/2.0);
      float lum = 1.15*(1+(dist1+1)/(dist1*dist1+dist1+1));
      if (dist0 < float(src.width)/2.0-3) {   
        dst.pixels[i+j*src.width] = color(128-3*dist1, 64, dist1);
      }
    }
  }
  //if (sin(i)+sin(j)<0) POUR PEPITES
  dst.updatePixels();
  return dst;
}////////////////////////////


PImage creerVersionSimple(float C0, float C1, float C2, float C3, float SUMW, float r0, float g0, float b0) {
  PImage dst = createImage((int)cellWidth, (int)cellHeight, ARGB);
  dst.loadPixels();

  for (int j=1; j<cellHeight; j++) 
    for (int i=1; i<cellWidth; i++) {
      float i0 = i-cellWidth/2;
      float j0 = j-cellHeight/2;
      float j1 = j-2*cellHeight/3;

      float dist = C0 * Math.max(Math.abs(i0), Math.abs(j0))+
        C1 * 0.5*(Math.abs(i0)+Math.abs(j0))+
        C2 * sqrt(i0*i0+j0*j0)+
        C3 * sqrt(i0*i0+j1*j1)*abs(2*j0/cellHeight+2);

      if (dist < float(cellWidth)/ (SUMW*(C0+C1+C2+C3)) ) {
        // ombrage haut-gauche vers bas-droit
        int lum = 220-(i*35/cellWidth)-(j*35/cellHeight);

        // plus epais au centre les bonbons sont donc un peu plus sombre au milieu
        lum =(4*lum+6*int(255*dist/(cellWidth/(SUMW*(C0+C1+C2+C3))) ))/9;

        // T2.4

        float distance = dist(dst.width/3, dst.height/3, i, j);
        dst.pixels[i+j*cellWidth] = color(35+lum*r0 + 3*(255-(35+lum*r0))/(distance+1), 
        35+lum*g0 + 3*(255-(35+lum*g0))/(distance+1), 
        35+lum*b0 + 3*(255-(35+lum*b0))/(distance+1));
      }
    }

  dst.updatePixels();
  return dst;
}////////////////////////////

// Crée l'image des cases de bonbons
PImage create_case() {
  // VARIABLES
  float x0 = cellWidth/2;
  float y0 = cellHeight/2;
  PImage image_case = createImage(cellWidth, cellHeight, ARGB);
  image_case.loadPixels();

  float d;
  for (int j = 0; j < cellHeight; j++) {
    for (int i = 0; i < cellWidth; i++) {
      d = dist(i, j, x0, y0);
      // CONTOURS DE LA CASE
      if (i < cellWidth /20  || i > cellWidth  - cellWidth /20 - 1 || 
        j < cellHeight/20  || j > cellHeight - cellHeight/20 - 1) {
        image_case.pixels[j*cellWidth+i] = color(100, 30, 100, 150);
      }
      // BORDS ARRONDIS AU MILIEU
      else if (d > 5*cellWidth/8 && d < cellWidth) {
        image_case.pixels[j*cellWidth+i] = color(((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth),
                                                 ((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth),
                                                 ((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth), 
                                                 220);
      }
      // FOND DU MILIEU DE LA CASE
      else {
        image_case.pixels[j*cellWidth+i] = color(((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth),
                                                 ((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth),
                                                 ((cellHeight*cellWidth-i*j)*255+(i*j)*50)/(cellHeight*cellWidth), 
                                                220);
      }
    }
  }

  return image_case;
}

// Traite le background pour le rendre plus terne et qu'il déconcentre moins
PImage traitement_bg(PImage bg) {

  bg.loadPixels();

  float r, g, b;
  for (int j = 0; j < bg.height; j++) {
    for (int i = 0; i < bg.width; i++) {
      r = red(bg.pixels[j*bg.width+i]);
      g = green(bg.pixels[j*bg.width+i]);
      b = blue(bg.pixels[j*bg.width+i]);
      bg.pixels[j*bg.width+i] = color(((r+g+b)/3 + r)/2, 
      ((r+g+b)/3 + g)/2, 
      ((r+g+b)/3 + b)/2);
    }
  }
  return bg;
}

void endGame(){
  while(!(keyPressed && (key == 10 || keyCode == ENTER))){
    println("endgame while loop");
  }
  exit();
}


void setup() {
  
  size(900, 680);
  //T 2.7
  bg = loadImage("BG.png");
  bg = traitement_bg(bg); // Rend le fond d'écran en semi-NB
  Winimage = loadImage("End.png");
  Loseimage = loadImage("Lose.png");

  // intitialisation des variables
  leftMargin = width/10;
  topMargin  = height/20;
  gridW      = 16;
  gridH      = 10;
  grid       = new int[gridH][gridW];
  gridDec    = new int[gridH][gridW];
  cellWidth  = (width-leftMargin)/gridW;
  cellHeight = (height-topMargin)/gridH;
  // On crée l'image des cases
  imgcase = create_case();
  
  // Score variables initialisation
  scoreScale = maxscore/(11.0*height/12.0 - height/6.0);

  // on cree la version coloree de chaque bonbon avec une forme donnee par des poids sur les distances
  imgs[0][0] = creerVersionSimple(0, -2, 3, 0, 1.400, 1.0, 0.0, 0.0);
  imgs[0][1] = creerVersionSimple(0, 0, 1, 0, 2.300, 0.0, 1.0, 0.0);
  imgs[0][2] = creerVersionSimple(2, 3, -1, 0, 0.230, 0.0, 0.0, 1.0);
  imgs[0][3] = creerVersionSimple(0, 3, 0.9, 0.6, 0.150, 1.0, 1.0, 0.0); // T2.3
  imgs[0][4] = creerVersionSimple(0, 0, 0, 3, 0.135, 1.0, 0.0, 1.0);

  // puis on applique des filtres pour faire les images de chaque variante de chaque type
  for (int i=0; i<maxElemTypes; i++) {
    imgs[1][i] = creerVersionOmbree(imgs[0][i]);
    imgs[2][i] = creerVersionOmbree(creerVersionRayeeHorizontal(imgs[0][i], i));
    imgs[3][i] = creerVersionOmbree(creerVersionRayeeVertical(imgs[0][i], i));
    imgs[4][i] = creerVersionOmbree(creerVersionSachet(imgs[0][i], i));// T2.5
    imgs[5][i] = creerVersionOmbree(creerVersionChoco(imgs[0][i], i));
  }

  setupLevel1();
  frameRate(50);
  noLoop();
}////////////////////////////


// compte combien de bonbons identiques sont alignes selon le vecteur di,dj
int countSame(int i, int j, int di, int dj) {
  int count = 0;
  int type = grid[j][i]%maxElemTypes;

  while (j+ (count+1)*dj>=0 && j+(count+1)*dj<gridH && 
    i+(count+1)*di>=0 && i+(count+1)*di<gridW && 
    grid[j+(count+1)*dj][i+(count+1)*di]%maxElemTypes==type &&
    grid[j+(count+1)*dj][i+(count+1)*di]<4*maxElemTypes) {
    count++;
  }
  return count;
}////////////////////////////


// determine si une case est dans un alignement de 3
boolean crushable(int i, int j) {
  int hor = countSame(i, j, +1, 0) + countSame(i, j, -1, 0)+1;
  int ver = countSame(i, j, 0, +1) + countSame(i, j, 0, -1)+1;
  return  (hor>=3 || ver>=3);
}////////////////////////////


// determine si une case n'est pas "solide" pour porter le bonbon du dessus
boolean emptyOrFalling(int i, int j) {
  if (i==animi && j==animj) return false;
  if (i==animi2 && j==animj2) return false;
  if (j==gridH-1) return (grid[j][i]==-1);
  else return (grid[j][i]==EMPTY) || emptyOrFalling(i, j+1) ;
}////////////////////////////


// determine si une case porte un bonbon raye (vertical ou horizontal)
boolean estRaye(int i, int j) {
  return (grid[j][i]>maxElemTypes && grid[j][i]<3*maxElemTypes) ;
}////////////////////////////


// demarre les bonbons qui tombent et cree les bonbons en haut si necessaire
void updateGrid() {
  boolean moreToFall = false;
  int     falling    = 0;
  int     created    = 0;
  int     crushed    = 0;
  accumulateurChute = 1;

  for (int j=gridH-1; j>=0; j--)
    for (int i=0; i<gridW; i++) {
      if (emptyOrFalling(i, j) && grid[j][i]!=EMPTY) { // une case vide(ou pleine d'un bonbon qui tombe) au dessous d'un bonbon le fait tomber !
        gridDec[j][i]= cellWidth*accumulateurChute; // T2.6
        falling++;
      } else if (grid[j][i]==EMPTY && j==0) {
        grid[j][i] = int(random(0, maxAvailTypes));
        created++;
        if (emptyOrFalling(i, j)) {
          gridDec[j][i]= cellWidth*accumulateurChute; // T2.4
          falling++;
        } else if (crushable(i, j)) 
          crushed += crush(i, j);
      }
    }

  if (crushed>0) updateGrid();
  if (falling>0) {
    startAnim(40, FALLING, -1, -1, -1, -1);
  } else if (created>0)
    redraw();
}////////////////////////////


// demarre une animation avec tous les parametres fournis
void startAnim(int count, int type, int i, int j, int i2, int j2) {
  //println("startAnim "+type+"  animRunning="+animRunning+" at "+i+", "+j+"=>"+grid[j][i]);
  if (!animRunning) {
    animRunning = true;
    animType    = type;
    animCount   = count;
    animi       = i;
    animj       = j;
    animi2      = i2;
    animj2      = j2;
    loop();
  }
}////////////////////////////

int power(int value, int pow){
  int result = 1;
  // Puissance positive
  if(pow > 0) {
    for(int i = 0; i < pow; i++){
      result *= value;
    }
  }
  // Puissance negative
  else if(pow < 0) {
    for(int i = 0; i > pow; i++){
      result /= value;
    }
  }
  return result;
}

//// stop l'animation et enleve/mange les bonbons /////////////////
void stopAnim() {
  //println("stopAnim "+animRunning+" "+animType);
  if (animRunning) {
    animRunning = false;
    int aT = animType;
    animType = NONE;

    noLoop();
    //int old = grid[animj][animi];
    int temp_score = 4;
    // selon le type d'animation, il ne faut pas enlever les memes bonbons
    if (aT==LASER) {
      score += 100;
      int other = grid[animj2][animi2];
      grid[animj][animi] = EMPTY;      
      for (int j0=0; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes == other%maxElemTypes && grid[j0][i0]<4*maxElemTypes)
            eat(i0, j0);
        }
    } else if (aT==HORI) {
      score += 30;
      grid[animj][animi] = EMPTY;
      for (int i0=0; i0<gridW; i0++) {
        eat(i0, animj);
      }
    } else if (aT==VERT) {
      score += 30;
      grid[animj][animi] = EMPTY;
      for (int j0=0; j0<gridH; j0++) {
        eat(animi, j0);
      }
    } else if (aT==SQBOOM) {
      score += 50;
      grid[animj][animi] = EMPTY;
      for (int j0=max (0, animj-1); j0<=min(gridH-1, animj+1); j0++)
        for (int i0=max (0, animi-1); i0<=min(gridW-1, animi+1); i0++)
          eat(i0, j0);
    } else if (aT==SQDBLBOOM) {
      score += 70;
      grid[animj][animi] = EMPTY;
      for (int j0=max (0, animj-2); j0<=min(gridH-1, animj+2); j0++)
        for (int i0=max (0, animi-2); i0<=min(gridW-1, animi+2); i0++) {
          eat(i0, j0);
        }
    } else if (aT==STARCROSS) {
      grid[animj][animi] = EMPTY;
      for (int j0=0; j0<gridH; j0++)
        eat(animi, j0);
      for (int i0=0; i0<gridW; i0++)
        eat(i0, animj);
    } else if (aT==BIGBONBON) {
      grid[animj][animi] = EMPTY;
      grid[animj2][animi2] = EMPTY;
      for (int j0=0; j0<gridH; j0++)
        for (int i0=max (0, animi-1); i0<=min(gridW-1, animi+1); i0++)
          eat(i0, j0);
      for (int i0=0; i0<gridW; i0++)
        for (int j0=max (0, animj-1); j0<=min(gridH-1, animj+1); j0++)
          eat(i0, j0);
    } else if (aT==SUPERLASER) {
      score += 150;
      grid[animj][animi] = EMPTY;
      grid[animj2][animi2] = EMPTY;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++)
          if (grid[j0][i0]<4*maxElemTypes) 
            eat(i0, j0);
    } else if (aT==DOUBLELASER) {
      score += 200;
      int other = grid[animj][animi];
      int target = grid[animj2][animi2];

      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes != target%maxElemTypes && grid[j0][i0]<2*maxElemTypes) {
            if (toCrush==0) {
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }

      grid[animj2][animi2] = EMPTY; //enleve le sachet
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes == target%maxElemTypes &&  (j0!=animj || i0!=animi) && (j0!=crushj || i0!=crushi) && grid[j0][i0]<4*maxElemTypes)
            eat(i0, j0);
        }

      animType    = LASER;
      animi2      = crushi;
      animj2      = crushj;
      animRunning = true;
      animCount   = 20;
      loop();
    } else if (aT==ALLSTRIP) {
      int other = grid[animj2][animi2];
      grid[animj][animi] = EMPTY;
      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes == other%maxElemTypes && grid[j0][i0]<2*maxElemTypes) {
            if (random(0, 2)<=1)
              grid[j0][i0] = (grid[j0][i0]%maxElemTypes)+2*maxElemTypes; // rend le bonbon raye
            else 
              grid[j0][i0] = (grid[j0][i0]%maxElemTypes)+maxElemTypes; // rend le bonbon raye
            if (toCrush==0) {
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      if (toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      }
    } else if (aT==ALLSTRIP3) {
      animRunning = true;
      for (int j0=1; j0<gridH; j0++) {
        if (j0!=animj) eat(animi, j0);
      }

      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes == grid[animj][animi]%maxElemTypes && 
            (j0!=animj||i0!=animi) && estRaye(i0, j0) && !emptyOrFalling(i0, j0)) {
            if (toCrush==0) {
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      grid[animj][animi] = EMPTY;
      if (toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      } else {
        animRunning = false;
      }
    } else if (aT==ALLSTRIP2) {
      animRunning = true;
      for (int i0=0; i0<gridW; i0++) {
        if (i0!=animi) eat(i0, animj);
      }
      int toCrush = 0;
      int crushi=-1;
      int crushj=-1;
      for (int j0=1; j0<gridH; j0++)
        for (int i0=0; i0<gridW; i0++) {
          if (grid[j0][i0]%maxElemTypes == grid[animj][animi]%maxElemTypes && 
            (j0!=animj||i0!=animi) && estRaye(i0, j0)  && !emptyOrFalling(i0, j0)) {
            if (toCrush==0) {
              crushi = i0;
              crushj = j0;
            }
            toCrush++;
          }
        }
      grid[animj][animi] = EMPTY;
      if (toCrush>0) {
        if (grid[crushj][crushi]>=maxElemTypes && grid[crushj][crushi]<2*maxElemTypes)
          animType= ALLSTRIP2;
        else
          animType= ALLSTRIP3;
        animi = crushi;
        animj = crushj;
        animRunning = true;
        animCount   = 20;
        loop();
      } else {
        animRunning = false;
      }
    }
    if (!animRunning) {
      animj  = -1;
      animi  = -1;   
      animj2 = -1;
      animi2 = -1;
    }
    score += temp_score;
  }
}// stopAnim() //////////////////////////


void eat(int i, int j) {
  //println("eat "+i+" "+j+" "+grid[j][i]);
  int old = grid[j][i];
  if (old==EMPTY) {
    // NOTHING
  } else if (old<maxElemTypes) {
    grid[j][i] = EMPTY;
  } else if (old<2*maxElemTypes){
    startAnim(20, HORI, i, j, -1, -1);
  }
  else if (old<3*maxElemTypes) {
    startAnim(20, VERT, i, j, -1, -1);
  }
  else if (old<4*maxElemTypes) {
    startAnim(20, SQBOOM, i, j, -1, -1);
  }
  else if (old<5*maxElemTypes) {
    startAnim(20, LASER, i, j, -1, -1);
    
  }
}// eat ()///////////////////////


// en i,j dans la grille il y a des bonbons a detruire autour
// cette fonction les detuit (appel a la fonction eat) et retourne le nombre exact de bonbon detruits 
int crush(int i, int j) {
  int crushed = 0;
  int type    = grid[j][i]%maxElemTypes;
  int hor     = countSame(i, j, +1, 0) + countSame(i, j, -1, 0)+1;
  int ver     = countSame(i, j, 0, +1) + countSame(i, j, 0, -1)+1;
  eat(i, j);
  int replace = EMPTY;

  // cas speciaux, preparation du bonbon special.
  if (hor>=5 || ver>=5)
    replace = type+4*maxElemTypes; // meme type mais en boule choco
  else if (hor>=3 && ver>=3)
    replace = type+3*maxElemTypes; // meme type mais en sachet
  else if (hor>=4)
    replace = type+2*maxElemTypes; // meme type mais en raye vertical 
  else if (ver>=4)
    replace = type+1*maxElemTypes; // meme type mais en raye horizontal
  else 
    crushed++; // sera juste detruit dans la liste de 3 


  if (hor>=3) { // il faut detruire les bonbons sur l'horizontale
    int i0=i-1;
    while (i0>=0 && grid[j][i0]>=0 && grid[j][i0]%maxElemTypes==type && grid[j][i0]<4*maxElemTypes) {
      eat(i0, j); 
      i0--;
      crushed++;
    }
    i0=i+1;
    while (i0<gridW && grid[j][i0]>=0 && grid[j][i0]%maxElemTypes==type && grid[j][i0]<4*maxElemTypes) {
      eat(i0, j); 
      i0++;
      crushed++;
    }
  }
  if (ver>=3) { // il faut detruire les bonbons sur la verticale
    int j0=j-1;
    while (j0>=0 && grid[j0][i]>=0 && grid[j0][i]%maxElemTypes==type && grid[j0][i]<4*maxElemTypes) {
      eat(i, j0); 
      j0--;
      crushed++;
    }
    j0=j+1;
    while (j0<gridH && grid[j0][i]>=0 && grid[j0][i]%maxElemTypes==type && grid[j0][i]<4*maxElemTypes) {
      eat(i, j0); 
      j0++;
      crushed++;
    }
  }

  // remplacement du bonbon qui a initie la destruction par un eventuel bonbon special
  // remplacement du bonbon qui a initie la destruction par un eventuel bonbon special
  // sauf si c'est lui meme un bonbon special ... auquel cas il faudrait mettre le bonbon special
  // cree au hasard a cote.
  if (i==animi && j==animj) {
    //TODO: deplacer le bonbon special si il y a lieu
  } else
    grid[j][i] = replace;
  return crushed;
}// crush()

void coups_effectue(){
 coups++;
}

void draw() {
  
  /* CONDITIONS DE FIN DE JEU
  if(endGameState)
    endGame();
  if (score > maxscore){
    
    
    endGameState = true;
    redraw();
  }*/
  
  // changements de phases de jeu
  if (score > maxscore && gameState == 0 && !animRunning){
    gameState = 1;
  }
  if(!(coups_restants-coups > 0) && gameState == 0 && !animRunning) {
    if(seuil2_franchi)
      gameState = 1;
    else if(seuil1_franchi)
      gameState = 1;
    else 
      gameState = 2;
  }

  if(gameState == 0){
  background(bg);
  imageMode(CENTER);
  stroke(0, 0, 0);
  textAlign(CENTER, CENTER);
  textSize(14); 

  int moving = 0;
  int crushed = 0;
  int created = 0;

  // Affichage du score
  fill(0,0,0,255);
  rect(width/2 - 30, 0, width, topMargin);
  textSize(22);
  fill(0, 150, 200, 204);
  text("SCORE : ", width/2 + width/20, height/50);
  fill(255,255,255,255);
  textAlign(LEFT, CENTER);
  text(score, width/2 + textWidth("SCORE : ") + width/100, height/50);
  
  // Affichage du nombre de coups
  fill(0, 150, 200, 204);
  text("COUPS RESTANTS : ", width/2 + width/15 + textWidth("SCORE : ") + width/100 + textWidth(char(score)) + width/80, height/50);
  fill(255,255,255,255);
  text(coups_restants - coups, width/2 + width/15 + textWidth("SCORE : ") + width/100 + textWidth(char(score)) + width/80 + textWidth("COUPS RESTANTS : ") + width/100, height/50);
  
  // Score à atteindre jauge
  fill(0,0,0,255);
  rect(width/60, height/6, width/15, 3*height/4);
  
  // Score atteint en barre
  if(seuil3_franchi)
    fill(230,120,0,255);
  else if(seuil2_franchi)
    fill(200,150,0,255);
  else if(seuil1_franchi)
    fill(100,100,255,255);
  else
    fill(50,255,50,255);
  scoreHeight = score/scoreScale;
  rect(width/60, 11*height/12-scoreHeight, width/15, scoreHeight);
  
  // seuils
  fill(255,180,0,160);
  float seuilHeight = seuil3/scoreScale;
  rect(width/60, 11*height/12-seuilHeight, width/15, (11*height/12 - height/6) / 60);
  seuilHeight = seuil2/scoreScale;
  fill(255,210,0,160);
  rect(width/60, 11*height/12-seuilHeight, width/15, (11*height/12 - height/6) / 60);
  seuilHeight = seuil1/scoreScale;
  fill(255,255,0,160);
  rect(width/60, 11*height/12-seuilHeight, width/15, (11*height/12 - height/6) / 60);
  
  // Score max
  textSize((width/120)/(textWidth(char(maxscore)))*(width/25));
  fill(255,255,255,255);
  textMode(CENTER);
  text(maxscore, width/50, height/5);
  
  // dessin de la grille
  // T2.1
  for (int j=0; j<gridH; j++) {
    for (int i=0; i<gridW; i++) {
      image(imgcase, leftMargin + i * cellWidth + cellWidth/2, topMargin + j * cellHeight + cellHeight/2);
    }
  }

  // mouvement des bonbons 
  for (int j=gridH-1; j>=0; j--)
    for (int i=0; i<gridW; i++) {
      int rawtype = grid[j][i];
      if (rawtype>=0) {
        int type = grid[j][i]%maxElemTypes;
        int bonus = floor((grid[j][i]-type)/maxBonusTypes);
        float dx = gridDec[j][i]%cellWidth;
        float dy = gridDec[j][i]/cellWidth;
        if (dy>0 && dy<cellHeight && j<gridH-1 && emptyOrFalling(i, j+1) ) { // ca tombe !
          gridDec[j][i]+=cellWidth*accumulateurChute; //T2.6
          moving++;
          accumulateurChute += 1;
          if (accumulateurChute > 8) accumulateurChute = 8;
        }
      }
    }

  // on teste les bonbons qui tombent et si ils depassent un deplacement d'une case, on
  // les place effectivement une case plus bas ... et soit ils contnuent leur chute soit ils 
  // se posent et font eventuellement des combinaisons 
  for (int j=gridH-1; j>=0; j--)
    for (int i=0; i<gridW; i++) {
      int rawtype = grid[j][i];
      if (rawtype>=0) {
        int dx = gridDec[j][i]%cellWidth;
        int dy = gridDec[j][i]/cellWidth;
        if (dy >= cellHeight) {
          grid[j+1][i]    =  grid[j][i];
          grid[j][i]      = EMPTY;
          gridDec[j][i]   = 0;
          gridDec[j+1][i] = 0;  

          if (crushable(i, j+1) && (j+1==gridH-1 || !emptyOrFalling(i, j+2))) {
            crushed += crush(i, j+1);
          }
          if (grid[j][i]==-1 && j==0) {
            created ++;
            do {
              grid[j][i] = int(random(0, maxAvailTypes));
            } 
            while (crushable (i, j));
          }
          if (emptyOrFalling(i, j+1)) {
            gridDec[j+1][i] = cellWidth*32; 
            if (grid[j][i]!=-1)
              gridDec[j][i] = cellWidth*32;
          } else if (grid[j][i]!=-1) {
            if (crushable(i, j)) {
              crushed += crush(i, j);
            }
          }
        }
      }
    }

  // dessin des bonbons
  for (int j=gridH-1; j>=0; j--)
    for (int i=0; i<gridW; i++) {
      int rawtype = grid[j][i];
      if (rawtype>=0) {
        int type = grid[j][i]%maxElemTypes;
        int bonus = (grid[j][i]-type)/maxBonusTypes;
        float dx = gridDec[j][i]%cellWidth;
        float dy = gridDec[j][i]/cellWidth;

        if (dy>0)
          dx += 0.5*(3*noise(i+frameCount, j+frameCount));

        // decalle le bonbon vers son voisin (et vice versa) pour montrer la permutation en cours
        if (i==cellCX && j==cellCY && abs(cellCX-cellDX)+abs(cellCY-cellDY)==1) {
          dx = int((cellDX-cellCX)*cellWidth*propAnim);
          dy = int((cellDY-cellCY)*cellHeight*propAnim);
        } else if (i==cellDX && j==cellDY && abs(cellCX-cellDX)+abs(cellCY-cellDY)==1) {
          dx = int((cellCX-cellDX)*cellWidth*propAnim);
          dy = int((cellCY-cellDY)*cellHeight*propAnim);
        }

        // T3.4
        if ((animType==SQBOOM && i>=animi-1 && i<=animi+1 && j>=animj-1 && j<=animj+1)||
          (animType==SQDBLBOOM && i>=animi-2 && i<=animi+2 && j>=animj-2 && j<=animj+2)) {
          pushMatrix();
          translate(leftMargin+i*cellWidth+cellWidth/2+dx, topMargin+j*cellHeight+cellHeight/2+dy);
          scale(1.5-abs(animCount/10.0-1.5));
          image(imgs[bonus+1][type], noise(5), 0);
          popMatrix();
        } else {
          if (bonus==6) println("GLOUPS "+i+","+j+" => "+grid[j][i]);
          image(imgs[bonus+1][type], leftMargin + i*cellWidth + cellWidth/2 + dx, topMargin+j*cellHeight+cellHeight/2+dy);
        }
        //fill(0);
        //text(rawtype,              leftMargin+i*cellWidth+cellWidth/2+dx, topMargin+j*cellHeight+cellHeight/2+dy);
        //text(i+","+j,              leftMargin+i*cellWidth+cellWidth/2+dx, 15+topMargin+j*cellHeight+cellHeight/2+dy);
      }
    }


  // dessin des animations speciales
  if (moving==0 && crushed==0 && animType==FALLING) {
    stopAnim();
  }
  if (animCount==0 && animType!=NONE) {
    stopAnim();
    updateGrid();
  }
  if ((animType==HORI || animType==ALLSTRIP2) && animCount>0) {
    //T3.1 remplacer ce dessin de cercles 
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    arc(starti, startj, 80, 80, 0, 2*PI*animCount/20, PIE); // T3.1

    //T3.1 remplacer ce dessin du bonbon raye 
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    image(imgs[bonus+1][type], 0, 0);
    popMatrix();
  } else if ((animType==VERT || animType==ALLSTRIP3) && animCount>0) {
    //T3.1 remplacer ce dessin de cercles 
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    arc(starti, startj, 80, 80, 0, 2*PI*animCount/20, PIE); //T3.1

    //T3.1 remplacer ce dessin du bonbon raye 
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    image(imgs[bonus+1][type], 0, 0);
    popMatrix();
  } else if ((animType==LASER || animType==DOUBLELASER) && animCount>0) {
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    int typeLaser = grid[animj2][animi2]%maxElemTypes;
    animCount--;
    // T3.4
    stroke(255, 255, 128, 255);
    strokeWeight(3);
    for (int j0=0; j0<gridH; j0++)
      for (int i0=0; i0<gridW; i0++) {
        if (grid[j0][i0]%maxElemTypes == typeLaser && grid[j0][i0]<4*maxElemTypes) {
          int endi    = leftMargin+i0*cellWidth+cellWidth/2;
          int endj    = topMargin+j0*cellHeight+cellHeight/2;

          line(starti+(min(20, 30-animCount))*(endi-starti)/20, startj+(min(20, 30-animCount))*(endj-startj)/20, 
          starti+(max(0, 15-animCount))*(endi-starti)/20, startj+(max(0, 15-animCount))*(endj-startj)/20);
        }
      }
    strokeWeight(1);
  } else if (animType==SUPERLASER && animCount>0) {
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    int i0 = animCount%gridW;
    int j0 = floor(animCount/gridW);
    stroke(255, 255, 128, 255);
    strokeWeight(3);

    println(i0+","+j0);
    if (j0>0 && grid[j0][i0]<4*maxElemTypes) {
      int endi    = leftMargin+i0*cellWidth+cellWidth/2;
      int endj    = topMargin+j0*cellHeight+cellHeight/2;

      line(starti, startj, endi, endj);
    } 
    strokeWeight(1);
  } else if (animType==ALLSTRIP && animCount>0) {
    int starti    = leftMargin+animi*cellWidth+cellWidth/2;
    int startj    = topMargin+animj*cellHeight+cellHeight/2;
    int typeLaser = grid[animj2][animi2]%maxElemTypes;
    animCount--;

    stroke(255, 255, 128, 255);
    strokeWeight(3);
    for (int j0=0; j0<gridH; j0++)
      for (int i0=0; i0<gridW; i0++) {
        if (grid[j0][i0]%maxElemTypes == typeLaser && grid[j0][i0]<4*maxElemTypes) {
          int endi    = leftMargin+i0*cellWidth+cellWidth/2;
          int endj    = topMargin+j0*cellHeight+cellHeight/2;

          line(starti+(min(20, 30-animCount))*(endi-starti)/20, startj+(min(20, 30-animCount))*(endj-startj)/20, 
          starti+(max(0, 15-animCount))*(endi-starti)/20, startj+(max(0, 15-animCount))*(endj-startj)/20);
        }
      }
    strokeWeight(1);
  } else if (animType==SQBOOM || animType==SQDBLBOOM ) {
    animCount--;// T3.4
  } else if (animType==STARCROSS) {
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;// T3.4
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti;
      float endj    = startj+(20-animCount)*max(startj, height-startj)/20+random(0, 10);
      float ri = random(-cellWidth/2, cellWidth/2); 

      line(starti+ri, startj, endi+ri, endj);
      endj    = startj-(20-animCount)*max(startj, height-startj)/20-random(0, 10);
      line(starti+ri, startj, endi+ri, endj);
    }
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti+(20-animCount)*max(starti, width-starti)/20+random(0, 10);
      float endj    = startj;
      float rj = random(-cellHeight/2, cellHeight/2); 
      line(starti, startj+rj, endi, endj+rj);
      endi    = starti-(20-animCount)*max(starti, width-starti)/20-random(0, 10);
      line(starti, startj+rj, endi, endj+rj);
    }
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(1, (10-animCount));
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type], 0, 0);
    noTint();
    popMatrix();
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale((10-animCount), 1);
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type], 0, 0);
    noTint();
    popMatrix();
  } else if (animType==BIGBONBON) {
    float starti    = leftMargin+animi*cellWidth+cellWidth/2;
    float startj    = topMargin+animj*cellHeight+cellHeight/2;
    animCount--;
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti;
      float endj    = startj+(20-animCount)*max(startj, height-startj)/20+random(0, 10);
      float ri = random(-3*cellWidth/2, 3*cellWidth/2); 

      line(starti+ri, startj, endi+ri, endj);
      endj    = startj-(20-animCount)*max(startj, height-startj)/20-random(0, 10);
      line(starti+ri, startj, endi+ri, endj);
    }
    for (int k=0; k<25; k++) {
      stroke(255, 255, 128, 255);
      float endi    = starti+(20-animCount)*max(starti, width-starti)/20+random(0, 10);
      float endj    = startj;
      float rj = random(-3*cellHeight/2, 3*cellHeight/2); 
      line(starti, startj+rj, endi, endj+rj);
      endi    = starti-(20-animCount)*max(starti, width-starti)/20-random(0, 10);
      line(starti, startj+rj, endi, endj+rj);
    }
    int type  = grid[animj][animi]%maxElemTypes;
    int bonus = grid[animj][animi]/maxBonusTypes;
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale(3, (10-animCount));
    tint(255, 255, 255, 55+animCount*10);
    //println(animi+","+animj+""+grid[animj][animi]+"=>"+bonus+" "+type);
    image(imgs[bonus+1][type], 0, 0);
    noTint();
    popMatrix();
    pushMatrix();
    translate( leftMargin+animi*cellWidth+cellWidth/2, topMargin+animj*cellHeight+cellHeight/2);
    scale((10-animCount), 3);
    tint(255, 255, 255, 55+animCount*10);
    image(imgs[bonus+1][type], 0, 0);
    noTint();
    popMatrix();
  }

  // T3.2

  // T3.3

  if (crushed>0) updateGrid();
  if (created>0 && !animRunning) redraw();
  }// Affichage de jeu == gameState = 1
  
  else if (gameState == 1) { // Win
    background(Winimage);
    fill(255,255,255,255);
    float Height = height/8;
    float space = width/50;
    if (score >= maxscore) {
      text("Vous avez réussi à atteindre le score max :", width/4, Height);
      text(maxscore, width/4 + textWidth("Vous avez réussi à atteindre le score max : ") + space, Height);
    }
    else if (seuil3_franchi) {
      text("Vous avez franchi le 3eme seuil avec en score :", width/4, Height);
      text(score, width/4 + textWidth("Vous avez franchi le 3eme seuil avec en score :") + space, Height);
    }
    else if (seuil2_franchi) {
      text("Vous avez franchi le 2eme seuil avec en score :", width/4, Height);
      text(score, width/4 + textWidth("Vous avez franchi le 2eme seuil avec en score :") + space, Height);
    }
    else if (seuil1_franchi) {
      text("Vous avez franchi le 1er seuil avec en score :", width/4, Height);
      text(score, width/4 + textWidth("Vous avez franchi le 1er seuil avec en score :") + space, Height);
    }
    else {
      text("Erreur de seuil", width/4, Height);
    }
      
    text(" avec", width/3, 1.5 * Height);
    text(coups_restants - coups, width/3 + textWidth(" avec") + space, 1.5 * Height);
    text(" coups restants", width/3 + textWidth(" avec") + space + textWidth(char(coups_restants - coups)) + space, 1.5 * Height);
    if(sin(frameCount/10) > 0)
      text("APPUYEZ SUR N'IMPORTE QUELLE TOUCHE POUR QUITTER", width/5, 2 * Height);
  }
  
  else if (gameState == 2) { // Lose
    background(Loseimage);
    fill(255,50,50,255);
    float Height = height/8;
    float space = width/50;
    text("GAME OVER : Vous avez perdu avec un score de :", width/4, Height);
    text(score, width/4 + textWidth("GAME OVER : Vous avez perdu avec un score de :") + space, Height);
    if(sin(frameCount/10) > 0)
      text("APPUYEZ SUR N'IMPORTE QUELLE TOUCHE POUR QUITTER", width/4.5, 1.5 * Height);
  }
  
  else {
    exit();
  }
  
}// draw()


void mousePressed() {
  cellCX = (mouseX-leftMargin)/cellWidth;
  cellCY = (mouseY-topMargin)/cellHeight;
  if (cellCX<0 || cellCX>=gridW || cellCY<0 || cellCY>=gridH || animRunning) {
    cellCX = -1;
    cellCY = -1;
  }
}


void mouseDragged() {
  cellDX = (mouseX-leftMargin)/cellWidth;
  cellDY = (mouseY-topMargin)/cellHeight;
  float prevPropAnim=propAnim;
  propAnim=0.0;
  if (cellCX>=0 && cellCY>=0 && cellDX>=0 && cellDX<gridW && cellDY>=0 && cellDY<gridH && 
    grid[cellCY][cellCX]>=0 && grid[cellDY][cellDX]>=0) {
    if (cellDX!=cellCX)
      propAnim = min(1.0, abs((mouseX-float(cellCX*cellWidth+leftMargin+cellWidth/2))/cellWidth));
    else
      propAnim = min(1.0, abs((mouseY-float(cellCY*cellHeight+topMargin+cellHeight/2))/cellHeight));
    if (propAnim>0.0 && propAnim!=prevPropAnim) {
      redraw();
    }
  }
}


void mouseReleased() {
  //println("MR "+cellCX+","+cellCY);
  cellDX = -1;
  cellDY = -1;
  int cellRX = (mouseX-leftMargin)/cellWidth;
  int cellRY = (mouseY-topMargin)/cellHeight;
  if(score > seuil1 && !seuil1_franchi)
    seuil1_franchi = true;
  if(score > seuil2 && !seuil2_franchi)
    seuil2_franchi = true;
  if(score > seuil3 && !seuil3_franchi)
    seuil3_franchi = true;
  if (cellCX>=0 && cellCX<gridW && cellCY>=0 && cellCY<gridH && 
    cellRX>=0 && cellRX<gridW && cellRY>=0 && cellRY<gridH) {
    if (abs(cellRX-cellCX)+abs(cellRY-cellCY)==1 ) {
      int tmp = grid[cellCY][cellCX];
      grid[cellCY][cellCX]=grid[cellRY][cellRX];
      grid[cellRY][cellRX]=tmp;
      //println("in "+cellCX+", "+cellCY+" there is now "+grid[cellCY][cellCX]);
      //println("in "+cellRX+", "+cellRY+" there is now "+grid[cellRY][cellRX]);
      int crushed = 0;

      // Boule en chocolat jetee sur un bonbon simple
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]<maxElemTypes && grid[cellCY][cellCX]!=EMPTY) {
        coups_effectue(); 
        startAnim(20, LASER, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<maxElemTypes && grid[cellRY][cellRX]!=EMPTY) {
        coups_effectue();  
        startAnim(20, LASER, cellCX, cellCY, cellRX, cellRY);
        return;
      }

      // deux boules en chocolat l'une sur l'autre
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes) {
        coups_effectue();  
        startAnim(gridW*gridH, SUPERLASER, cellRX, cellRY, cellCX, cellCY);
        println("SL");
        return;
      }

      // une boule en chocolat sur un sachet
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes) {
        coups_effectue();  
        startAnim(20, DOUBLELASER, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes) {
        coups_effectue();  
        startAnim(20, DOUBLELASER, cellCX, cellCY, cellRX, cellRY);
        return;
      }

      // une boule en chocolat sur un bonbon raye
      if (grid[cellRY][cellRX]>=4*maxElemTypes && grid[cellCY][cellCX]>=2*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes) {
        coups_effectue();  
        startAnim(20, ALLSTRIP, cellRX, cellRY, cellCX, cellCY);
        return;
      } else if (grid[cellRY][cellRX]>=2*maxElemTypes && grid[cellCY][cellCX]>=4*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes) {
        coups_effectue();  
        startAnim(20, ALLSTRIP, cellCX, cellCY, cellRX, cellRY);
        return;
      }


      // sachet sur sachet
      if (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes) {
        coups_effectue();  
        startAnim(20, SQDBLBOOM, cellRX, cellRY, -1, -1);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }

      // raye sur raye
      if (grid[cellRY][cellRX]>=1*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes && grid[cellCY][cellCX]>=1*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes) {
        coups_effectue();  
        startAnim(20, STARCROSS, cellRX, cellRY, -1, -1);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }
      // raye sur sachet ou vice-versa
      if ((grid[cellRY][cellRX]>=1*maxElemTypes && grid[cellRY][cellRX]<3*maxElemTypes && grid[cellCY][cellCX]>=3*maxElemTypes && grid[cellCY][cellCX]<4*maxElemTypes) ||
        (grid[cellRY][cellRX]>=3*maxElemTypes && grid[cellRY][cellRX]<4*maxElemTypes && grid[cellCY][cellCX]>=1*maxElemTypes && grid[cellCY][cellCX]<3*maxElemTypes)) {
        coups_effectue();  
        startAnim(20, BIGBONBON, cellRX, cellRY, cellCX, cellCY);
        //grid[cellRY][cellRX] = EMPTY;
        //grid[cellCY][cellCX] = EMPTY;
        return;
      }

      // coup normal
      else {
        if (crushable(cellCX, cellCY)){
          score += 5;
          crushed += crush(cellCX, cellCY);
        }
        if (crushable(cellRX, cellRY)){
          score += 5;
          crushed += crush(cellRX, cellRY);
        }
        if (crushed>0 && animType==NONE) {
          coups_effectue();  
          updateGrid();
        } else {
          // le coup etait interdit car il ne detruit rien !
          tmp = grid[cellCY][cellCX];
          grid[cellCY][cellCX]=grid[cellRY][cellRX];
          grid[cellRY][cellRX]=tmp;
        }
      }
    }
  }
  redraw();
}

void keyPressed(){
  if((gameState == 1 || gameState == 2))
    exit();
}