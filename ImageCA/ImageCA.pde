ColorCA ca = null;

void setup()
{
  surface.setResizable(true);
  selectInput("Select an image", "fileSelected");
}

void fileSelected(File selection)
{
  if (null != selection)
  {
    PImage image = loadImage(selection.getAbsolutePath());
    if (null != image)
    {
      surface.setSize(image.width, image.height);
      image(image, 0, 0);
      ca = new ColorCA(image);
    }
  }
  
  if (null == ca)
  {
    selectInput("Select an image", "fileSelected");
  }
}

class ColorCA
{
  PImage img;
  
  ColorCA(PImage seed)
  {
    img = seed;
  }
  
  void step()
  {
    colorMode(HSB);
    
    PImage next = img.copy();
    
    img.loadPixels();
    next.loadPixels();
    for (int y = 0; y < img.height; ++y)
    {
      int rowOffset = y * img.width;
      for (int x = 0; x < img.width; ++x)
      {
        int pixelIndex = rowOffset + x;
        
        float h = 0;
        float s = 0;
        float v = 0;
        
        for (int iy = -1; iy <= 1; ++iy)
        {
          int ky = y + iy;
          if (ky < 0)
          {
            ky+= img.height;
          }
          if (ky >= img.height)
          {
            ky-= img.height;
          }
          int iRowOffset = ky * img.width;
          
          for (int ix = -1; ix <= 1; ++ix)
          {
            if (ix != 0 && iy != 0)
            {
              int kx = x + ix;
              if (kx < 0)
              {
                kx+= img.width;
              }
              if (kx >= img.width)
              {
                kx-= img.width;
              }
              int iPixelIndex = iRowOffset + kx;
            
              color c = img.pixels[iPixelIndex];
              h += hue(c);
              s += saturation(c);
              v += brightness(c);
            }
          }
        }
        
        final float thresh = 0.1;
        
        h/= 8;
        float oldH = hue(next.pixels[pixelIndex]);
        if (h == thresh)
        {
          // do nothing
        }
        else if (h > thresh)
        {
          h = oldH - 1;
          h = max(0, h);
        }
        else
        {
          h = oldH + 1;
          h = min(h, 0xFF);
        }

        s/= 8;
        float oldS = saturation(next.pixels[pixelIndex]);
        if (s == thresh)
        {
  // Do nothing?
        }
        else if (s > thresh)
        {
          s = oldS - 1;
          s = max(0, s);
        }
        else
        {
          s = oldS + 1;
          s = min(s, 0xFF);
        }

        v/= 8;
        float oldV = brightness(next.pixels[pixelIndex]);
        if (v == thresh)
        {
          // do nothing
        }
        else if (v > thresh)
        {
          v = oldV - 1;
          v = max(0, v);
        }
        else
        {
          v = oldV + 1;
          v = min(v, 0xFF);
        }

        next.pixels[pixelIndex] = color(h, s, v);
      }
    }

    next.updatePixels();
    img = next;
  }
}

void draw()
{
  if (null != ca)
  {
    ca.step();
    image(ca.img, 0, 0);
  }
}