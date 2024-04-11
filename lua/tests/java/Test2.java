public class Test2 {

  public static int MY_CONST = 16;

  public void function1() {}

  public enum TestEnum {
    V1,
    V2
  }

  public String transformString(String input) {
    int localVar = MY_CONST;
    anyName();
    return input + "/";
  }

  private String field;

  public void anyName() {
    return this.field;
  }
}
