import com.example.External;
import package1.ClassOne;
import java.util.Arrays;

public class Test extends Test2 implements Test2 {

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
    int field = 6;
    return this.field + "/";
  }

  private String testMethodRefThis() {
    Arrays.asList("a", "b").forEach(this::transformString);
    Test2.transformString("te");
    ClassOne val = new ClassOne();
  }

  private static void Test2() {
    Test2 myVar = new Test2();
    myVar.transformString("te");
  }

  private List<Integer> vals = Arrays.asList(Test2.MY_CONST);
  private int anyName = 0;

  private void modif(Test2 transformString) {
    this.anyName++;
    transformString.transformString();
    testMethodRefThis();
    return field;
  }

  public Test() {
    super();
  }

  static class Inner extends External {
    public Inner() {
      super();
    Arrays.asList("a", "b").forEach(Test2::new);
    }
  }
}
