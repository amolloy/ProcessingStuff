def setup():
    size(800, 800)
    noLoop()
    
def draw():
    maxDistSq = width * width + height * height

    loadPixels()

    pts=[]
    for y in range(0, height):
        for x in range(0, width):
            ptc = noise(x, y)
            pixels[y * width + x] = color(ptc * 255.0)
            if ptc > 0.88:
                pts.append([x, y])
    updatePixels()
      
    println("Noise done.")
 
      
    pts = []
    while(len(pts) == 0):
        pts = []
        for y in range(0, height):
            for x in range(0, width):
                wtf = random(1.0) * 100.0
                if wtf > 99.95:
                    pts.append([x, y])
    
    println("Drawing (" + str(len(pts)) + ")")
                     
    loadPixels()
    for y in range(0, height):
        for x in range(0, width):
            closest=pts[0]
            closestDistSq = maxDistSq
            for pt in pts:
                distX = x - pt[0]
                distY = y - pt[1]
                distSq = distX * distX + distY * distY
                if distSq < closestDistSq:
                    closest = pt
                    closestDistSq = distSq
            distScale = sqrt(closestDistSq) / (width * 0.1)
            pixels[y * width + x] = color(distScale * 255)
    
    updatePixels()
    
    println("Done.")
    