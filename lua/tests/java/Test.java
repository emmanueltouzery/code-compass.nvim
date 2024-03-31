import com.example.External;
import package1.ClassOne;
import java.util.Arrays;

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
    int field = 6;
    return this.field + "/";
  }

  private String testMethodRefThis() {
    Arrays.asList("a", "b").forEach(this::transformString);
    Test2.transformString("te");
    ClassOne val = new ClassOne();
  }
}
