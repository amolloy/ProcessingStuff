import java.util.HashMap;

LSystem ls;


void setup() 
{
  size(800, 800);
  createFernLSystem();
}

void createFernLSystem()
{
  ls = new LSystem("X");
  ls.addRule('X', "FL[[X]RX]RF[RFX]LX");
  ls.addRule('F', "FF");
  
  ls.addInstruction('F', new DrawLine(-4.5));
  ls.addInstruction('R', new Rotate(-25));
  ls.addInstruction('L', new Rotate(25));
  ls.addInstruction('[', new Push());
  ls.addInstruction(']', new Pop());
}

void createTreeLSystem()
{
  ls = new LSystem("0");
  ls.addRule('1', "11");
  ls.addRule('0', "1[0]0");
  ls.addInstruction('0', new DrawLine(5));
  ls.addInstruction('1', new DrawLine(5));
  ls.addInstruction('[', new PushAndRotate(45));
  ls.addInstruction(']', new PopAndRotate(-45));
}

void draw() 
{
  translate(width / 2, height);
  ls.renderGeneration(6);
  noLoop();
  saveFrame();
}

public static interface Instruction
{
  void execute(LSystem lSystem);
}

class LSystem
{
  String axiom;
  HashMap<Character, String> rules;
  HashMap<Character, Instruction> instructions;

  LSystem(String axiom)
  {
    this.axiom = axiom;
    rules = new HashMap<Character, String>();
    instructions = new HashMap<Character, Instruction>();
  }
  
  void addRule(Character rule, String production)
  {
    rules.put(rule, production);
  }
  
  void addInstruction(Character code, Instruction instruction)
  {
    instructions.put(code, instruction);
  }
  
  String productionForGeneration(int generation)
  {
    if (generation == 0)
    {
      return axiom;
    }
    String productionForGenM1 = productionForGeneration(generation - 1);
    String production = new String();
    for (int i = 0; i < productionForGenM1.length(); ++i)
    {
      char c = productionForGenM1.charAt(i);
      String rule = rules.get(c);
      if (rule != null)
      {
        production = production + rule;
      }
      else
      {
        production = production + c;
      }
    }
    
    return production;
  }
  
  void renderGeneration(int generation)
  {
    String production = productionForGeneration(generation);
    for (int i = 0; i < production.length(); ++i)
    {
      char c = production.charAt(i);
      Instruction instruction = instructions.get(c);
      if (instruction != null)
      {
        instruction.execute(this);
      }
    }
  }
}

class DrawLine implements Instruction
{
  float lineLength;
  
  DrawLine(float lineLength)
  {
    this.lineLength = lineLength;
  }
  
  void execute(LSystem lSystem)
  {
    noFill();
    stroke(0xFFFFFFFF);
    line(0, 0, 0, lineLength);
    translate(0, lineLength);
  }
}

class Push implements Instruction
{
  void execute(LSystem lSystem)
  {
    pushMatrix();
  }
}

class Pop implements Instruction
{
  void execute(LSystem lSystem)
  {
    popMatrix();
  }
}

class Rotate implements Instruction
{
  float theta;
  
  public Rotate(float theta)
  {
    this.theta = (float)Math.toRadians(theta);
  }
  
  void execute(LSystem lSystem)
  {
    rotate(theta);
  }
}

class CompositeInstruction implements Instruction
{
  Instruction instructions[];
  
  public CompositeInstruction(Instruction instructions[])
  {
    this.instructions = instructions;
  }
  
  void execute(LSystem lSystem)
  {
    for (Instruction instruction : instructions)
    {
      instruction.execute(lSystem);
    }
  }
}

class PushAndRotate extends CompositeInstruction
{
  PushAndRotate(float theta)
  {
    super(new Instruction[] { new Push(), new Rotate(theta) });
  }
}

class PopAndRotate extends CompositeInstruction
{
  PopAndRotate(float theta)
  {
    super(new Instruction[] { new Pop(), new Rotate(theta) });
  }
}