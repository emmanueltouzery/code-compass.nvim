import com.example.External;

public class Test {

  private String field;

  public String getField() {
    int localVar = 2;
    System.out.println(localVar + 1);
    External var = new External(Test2.MY_CONST);
    return field;
  }

  private void action() {
    (new Test2()).function1();
    TestEnum v = TestEnum.V1;
  }

  public static int MY_CONST = 16;

  private String testMethodRef() {
    Arrays.asList("a", "b").forEach(Test2::transformString);
  }

  public String transformString(String input) {
    return input + "/";
  }
}
