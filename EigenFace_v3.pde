import java.util.*;
import processing.video.*;

EigenObjects eigenFace, maleFace, femaleFace;
Capture cam;
int spx, spy, spscale;
int scaleD = 100;
int skipPixels = 20;
int skipStep = 5, scaleSkipStep = 10;
int sw = 4;
int scene = 0;
int testNumber = 21;
PImage test;
PImage yes, no, loading;
ArrayList<Square> faceArea = new ArrayList<Square>();

void setup() {
  size(1280, 720);
  frameRate(10000);
  yes = loadImage("yes.gif");
  no = loadImage("no.png");
  setupCamera();
  loading = loadImage("loading.gif");
  image(loading, width / 2 - loading.width / 2, height / 2 - loading.height / 2);
}

void draw() {
  
  if(scene == 0) {
    eigenFace = new EigenObjects("lfw1000/", 259, 26);
    maleFace = new EigenObjects("male/", 195, 20);
    femaleFace = new EigenObjects("female/", 61, 5);
    scene = 4;
  } else if(scene <= testNumber) {
    background(255);
    textSize(30);
    fill(0, 255, 0);
    text("Real Time", 550, 670);
    int i = scene;
    test = loadImage("test"+ i + ".jpg");
    image(test, 0, 0);
    PImage gimg = convertToGreyImage(test);
    Square object = searchFace(gimg);
    if(object.faceExists) {
      String gender = checkGender(gimg, object);
      renderGenderLabel(gender, object.sx, object.ey);
      color c;
      if(gender.equals("male")) c = color(0,0,255);
      else c = color(255,0,0);
      object.drawSquare(c);
      image(yes, test.width + sw, 0);
    } else {
      image(no, test.width + sw, 0);
    }
  }else if(scene == testNumber + 1){
    if (cam.available() == true) {
      background(255);
      cam.read();
      int w = cam.width, h = cam.height;
      test = cam.get((w - h)/2, 0, h, h);
      image(test, 0, 0);
      test.resize(100, 100);
      //image(test, 0, 0);
      PImage gimg = convertToGreyImage(test);
      Square object = searchFace(gimg);
      if(object.faceExists) {
        String gender = checkGender(gimg, object);
        object.zoom((double)h / (double)100.0);
        color c;
        if(gender.equals("male")) c = color(0,0,255);
        else c = color(255,0,0);
        object.drawSquare(c);
        image(yes, w + sw, 0);
        renderGenderLabel(gender, object.sx, object.ey);
      } else {
        image(no, w + sw, 0);
      }
    }
  } else {
    scene = 1;
  } //<>//
}

void mousePressed() {
  if(mouseX >= 550 && mouseY >= 640) {
    scene = testNumber + 1;
  } else {
    scene++;
  }
}

void setupCamera() {
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // The camera can be initialized directly using an 
    // element from the array returned by list():
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
  
}

String checkGender(PImage gimg, Square object) {
  int k = 3, m = 0, f = 0;
  PImage timg = gimg.get(object.sx, object.sy, object.ex - object.sx, object.ey - object.sy);
  timg.resize(eigenFace.trainWidth, eigenFace.trainHeight);
  double male[] = maleFace.kNearestNeighbors(k,timg);
  double female[] = femaleFace.kNearestNeighbors(k,timg);
  for(int i = 0; i < k; i++){
    if(male[i] < female[i]) m++;
    else f++;
  }
  if(m > f) {
    return "male";
  } else {
    return "female";
  }
}

void renderGenderLabel(String gender, int x, int y){
  textSize(32);
  if(gender.equals("male")) {
    fill(0, 0, 255);
  }else{
    fill(255, 0, 0);
  }
  text(gender, x, y + 32);
}

Square searchFace(PImage tImg) {
  Square result = new Square(0, 0, tImg.width, tImg.height);
  
  if(tImg.width <= eigenFace.trainWidth && tImg.height <= eigenFace.trainHeight) {
    tImg.resize(eigenFace.trainWidth, eigenFace.trainHeight);
    double testResult[] = eigenFace.kNearestNeighbors(1, tImg);
    if(testResult[0] < 3E7) result.faceExists = true;
    else result.faceExists = false;
    return result;
  }
  int maxSize = Math.min(tImg.width, tImg.height);
  int minSize = Math.max(maxSize - scaleD, test.width / 2);
  for(int size = maxSize; size >= minSize; size -= scaleSkipStep) {
    int d = 0;
    if(size - maxSize > skipPixels) d = skipPixels;
    for(int y = 0 + d; y <= tImg.height - size - d; y += skipStep)
      for(int x = 0 + d; x <= tImg.width - size - d; x += skipStep) {
        PImage nImg = tImg.get(x, y, size, size);
        nImg.resize(eigenFace.trainWidth, eigenFace.trainHeight);
        double testResult[] = eigenFace.kNearestNeighbors(1, nImg);
        if(testResult[0] < 3E7) {
          result.faceExists = true;
          result.sx = x; result.sy = y;
          result.ex = x + size; result.ey = y + size;
          return result;
        }
      }
  }
  
  return result;
}

PImage convertToGreyImage(PImage oimg) {
  PImage gimg = new PImage(oimg.width, oimg.height);
  
  loadPixels();
  for(int x = 0; x < oimg.width; x++)
    for(int y = 0; y < oimg.height; y++) {
      int loc = x + oimg.width * y;
      float r = red(oimg.pixels[loc]);
      float g = green(oimg.pixels[loc]);
      float b = blue(oimg.pixels[loc]);
      float gx = 0.21267 * r + 0.715160 * g + 0.072169 * b;
      color c = color(gx);
      gimg.pixels[loc] = c;
    }
  updatePixels();
  
  return gimg;
} //<>//

public class Square {
  public int sx, sy, ex, ey;
  public boolean faceExists;
  Square(int sx, int sy, int ex, int ey) {
    this.faceExists = false;
    this.sx = sx;
    this.sy = sy;
    this.ex = ex;
    this.ey = ey;
  }
  
  public boolean checkCross(Square r) {
    int minx = Math.max(this.sx, r.sx);
    int miny = Math.max(this.sy, r.sy);
    int maxx = Math.min(this.ex, r.ex);
    int maxy = Math.min(this.ey, r.ey);
    
    if(minx > maxx || miny > maxy)
      return false;
      
    return true;
  }
  
  public void zoom(double times) {
    double sx1 = (double)sx * times;
    double sy1 = (double)sy * times;
    double ex1 = (double)ex * times;
    double ey1 = (double)ey * times;
    sx = (int)sx1;
    sy = (int)sy1;
    ex = (int)ex1;
    ey = (int)ey1;
  }
  
  public void drawSquare(color c) {
    stroke(c);
    strokeWeight(sw);
    line(sx, sy, ex, sy);
    line(sx, sy, sx, ey);
    line(ex, sy, ex, ey);
    line(sx, ey, ex, ey);
  }
}

public class EigenMatrixSimulation {
  public double eigenValue;
  public Matrix eigenMat;
  
  EigenMatrixSimulation(double v, Matrix m) {
    eigenValue = v;
    eigenMat = m;
  }
}

public class EigenObjects{
  
Comparator c0 = new Comparator<EigenMatrixSimulation>() {  
  @Override  
  public int compare(EigenMatrixSimulation o1, EigenMatrixSimulation o2) {  
    // TODO Auto-generated method stub  
    double v1 = o1.eigenValue;
    double v2 = o2.eigenValue;
    if(v1 < v2)  
      return 1;   
    else return -1;  
  }  
};      
  public int sampleNumber;
  public int amount, trainWidth, trainHeight;
  public String path;
  public ArrayList<PImage> objects = new ArrayList<PImage>();
  public ArrayList<double[][]> objectsDiffDouble = new ArrayList<double[][]>();
  public PImage averageObjectImage;
  public Matrix rEigenFace, gEigenFace, bEigenFace;
  public Matrix rPhi, gPhi, bPhi;
  public Matrix rWTrain, gWTrain, bWTrain;
  public ArrayList<PImage> eigenObjectsOutput = new ArrayList<PImage>();
  
  EigenObjects(String path, int amount, int sn) {
    this.sampleNumber = sn;
    this.amount = amount;
    this.path = path;
    for(int i = 1; i <= amount; i++) {
      objects.add(loadImage(path + i + ".jpg"));
    }
    averageObjectImage = calculateAverageImage(objects);
    trainWidth = averageObjectImage.width;
    trainHeight = averageObjectImage.height;
    
    for(int i = 0; i < objects.size(); i++) {
      objectsDiffDouble.add(
        calculateImageDifferenceReturnDouble(
          objects.get(i), 
          averageObjectImage)
      );
    }
    double objectDiffCollection[][][] =  getPhiMatrices(objectsDiffDouble, objectsDiffDouble.size());
    rEigenFace = getEigenImageMatrix(objectDiffCollection[0]);
    gEigenFace = getEigenImageMatrix(objectDiffCollection[1]);
    bEigenFace = getEigenImageMatrix(objectDiffCollection[2]);
    test(rEigenFace, gEigenFace, bEigenFace);
    rPhi = new Matrix(objectDiffCollection[0]);
    gPhi = new Matrix(objectDiffCollection[1]);
    bPhi = new Matrix(objectDiffCollection[2]);
    rWTrain = rEigenFace.transpose().times(rPhi.transpose());
    gWTrain = gEigenFace.transpose().times(gPhi.transpose());
    bWTrain = bEigenFace.transpose().times(bPhi.transpose());
  }

public double[] kNearestNeighbors(int k, PImage t) {
  double result[] = new double[k];
  
  for(int i = 0; i < k; i++)
    result[i] = Double.MAX_VALUE;
    
  double tImgDouble[][] = imageToSingleRowVector(t);
  double mImgDouble[][] = imageToSingleRowVector(averageObjectImage);
  Matrix tImgMatrix = (new Matrix(tImgDouble)).transpose();
  Matrix mImgMatrix = (new Matrix(mImgDouble)).transpose();
  Matrix dImgMatrix = tImgMatrix.minus(mImgMatrix);
  Matrix dImgMatrixR = dImgMatrix.getMatrix(0, dImgMatrix.getRowDimension() - 1, 0, 0);
  Matrix rWTest = rEigenFace.transpose().times(dImgMatrixR);
  
  for(int i = 0; i < sampleNumber; i++) {
    double tmp = euclideanDistance(rWTrain.getMatrix(0, rWTrain.getRowDimension() - 1, i, i), rWTest);
    if(tmp < result[k - 1]) {
      result[k - 1] = tmp;
      Arrays.sort(result);
    }
  }
  
  return result;
}

double euclideanDistance(Matrix a, Matrix b) {
  double result = 0;
  
  for(int i = 0; i < a.getRowDimension(); i++) {
    result += Math.pow(a.get(i, 0) - b.get(i, 0), 2.0);
  }
  result = Math.sqrt(result);
  
  return result;
}
  
void test(Matrix a, Matrix b, Matrix c) {
  for(int i = 0; i < a.getColumnDimension(); i++) {
    double tmp[][] = new double[3][4096];
    for(int j = 0; j < 4096; j++) {
      tmp[0][j] = a.get(j, i);
      tmp[1][j] = b.get(j, i);
      tmp[2][j] = c.get(j, i);
    }
    eigenObjectsOutput.add(singleRowVectorToImage(tmp, 64, 64));
  }
}
  
  
Matrix getEigenImageMatrix(double oMatrix[][]) {
  Matrix aMatrix = new Matrix(oMatrix);
  Matrix cMatrix = aMatrix.times(aMatrix.transpose());
  Matrix eigMat = cMatrix.eig().getV();
  Matrix eigVal = cMatrix.eig().getD();

  ArrayList<EigenMatrixSimulation> imgEigenMatrixSims = new ArrayList<EigenMatrixSimulation>();
  int matSize = cMatrix.getRowDimension();
  for(int i = 0; i < matSize; i++) {
    imgEigenMatrixSims.add(
      new EigenMatrixSimulation(eigVal.get(i, i), eigMat.getMatrix(0, matSize - 1, i, i))
    );
  }
  imgEigenMatrixSims.sort(c0);
  Matrix sortedEigMat = new Matrix(matSize, matSize);
  for(int i = 0; i < matSize; i++) {
    sortedEigMat.setMatrix(0, matSize - 1, i, i, imgEigenMatrixSims.get(i).eigenMat);
  }
  Matrix eigenFaces = aMatrix.transpose().times(sortedEigMat);

  return eigenFaces;
}

double[][][] getPhiMatrices(ArrayList<double[][]> oData, int size) {
  double result[][][] = new double[3][size][];
  
  for(int i = 0; i < size; i++){
    double tmp[][] = oData.get(i);
    result[0][i] = tmp[0];
    result[1][i] = tmp[1];
    result[2][i] = tmp[2];
  }
  //println(result[0][1]);
  return result;
}

double[][] imageToSingleRowVector(PImage oimg){
  double result[][] = new double[3][oimg.width * oimg.height];
  
  loadPixels();
  for(int y = 0; y < oimg.height; y++)
    for(int x = 0; x < oimg.width; x++) {
      int loc = x + y * oimg.width;
      
      result[0][loc] = red(oimg.pixels[loc]);
      result[1][loc] = green(oimg.pixels[loc]);
      result[2][loc] = blue(oimg.pixels[loc]);
    }
    
  return result;
}

PImage singleRowVectorToImage(double[][] v, int w, int h) {
  PImage result = new PImage(w, h);
  
  for(int y = 0; y < h; y++)
    for(int x = 0; x < w; x++) {
      int loc = x + y * w;
      int r = (int)v[0][loc];
      int g = (int)v[1][loc];
      int b = (int)v[2][loc];
      
      result.pixels[loc] = color(r, g, b);
    }
  updatePixels();
  
  return result;
}

double[][] calculateImageDifferenceReturnDouble(PImage oimg, PImage mimg) {
  double result[][] = new double[3][oimg.width * oimg.height];
  
  loadPixels();
  for(int x = 0; x < mimg.width; x++)
    for(int y = 0; y < mimg.height; y++) {
      int loc = x + y * mimg.width;
      result[0][loc] = red(oimg.pixels[loc]) - red(mimg.pixels[loc]);
      result[1][loc] = green(oimg.pixels[loc]) - green(mimg.pixels[loc]);
      result[2][loc] = blue(oimg.pixels[loc]) - blue(mimg.pixels[loc]);
    }
  
  return result;
}
/*
* Calculate Average Images
* Input: images list
* Output: single image that has average data
*/
PImage calculateAverageImage(ArrayList<PImage> oimgs) {
  PImage result = new PImage(oimgs.get(0).width, oimgs.get(0).height);
  float r[] = new float[result.width * result.height]; 
  float g[] = new float[result.width * result.height]; 
  float b[] = new float[result.width * result.height];
  for(int x = 0; x < result.width; x++)
    for(int y = 0; y < result.height; y++) {
      int loc = x + y * result.width;
      r[loc] = 0; g[loc] = 0; b[loc] = 0;
    }
    
  loadPixels();
  for(int i = 0; i < oimgs.size(); i++) {
    PImage img = oimgs.get(i);
    for(int x = 0; x < img.width; x++)
      for(int y = 0; y < img.height; y++) {
        int loc = x + y * img.width;
        r[loc] += red(img.pixels[loc]);
        g[loc] += green(img.pixels[loc]);
        b[loc] += blue(img.pixels[loc]);
      }
  }
  for(int x = 0; x < result.width; x++)
    for(int y = 0; y < result.height; y++) {
      int loc = x + y * result.width;
      r[loc] /= (float) oimgs.size();
      g[loc] /= (float) oimgs.size();
      b[loc] /= (float) oimgs.size();
      result.pixels[loc] = color(r[loc], g[loc], b[loc]);
    }
  updatePixels();
  
  return result;
}
}