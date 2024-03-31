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
  }
}
