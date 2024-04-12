package it.planetek.rheticus.displacement.etl;

import org.apache.commons.lang3.StringUtils;
import org.junit.rules.TestName;
import org.junit.runner.Description;
import org.slf4j.Logger;


/**
 * The Class LoggingRule.
 */
public class LoggingRule
        extends TestName
{
    private static Logger       log;
    private static String       resultTest;

    private static final int    REPEAT_CHAR = 50;
    private static final String HEADER_01   = StringUtils.repeat("=", REPEAT_CHAR);
    private static final String HEADER_02   = StringUtils.repeat("-", REPEAT_CHAR);
    private static final String FOOTER_01   = StringUtils.repeat("-", REPEAT_CHAR);
    private static final String FOOTER_02   = StringUtils.repeat("=", REPEAT_CHAR);

    /**
     * Instantiates a new logging rule.
     * 
     * @param log
     *            the log
     */
    public LoggingRule(final Logger log) {
        super();
        LoggingRule.log = log;
    }

    @Override
    public void starting(final Description method) {
        String unitTestClassName = method.getClassName();  // method.getMethod().getDeclaringClass().getCanonicalName();
        String unitTestMethodName = method.getMethodName(); // method.getName();
        String spliChar = ".";

        if (unitTestClassName.contains(spliChar)) {
            String[] unitTestClassNameSplitted = unitTestClassName.split("\\" + spliChar);
            unitTestClassName = unitTestClassNameSplitted[unitTestClassNameSplitted.length - 1];
        }

        // System.out.printf("\t%s\n", HEADER_01);
        // System.out.printf("\tTest Case: %s \n", unitTestClassName);
        // System.out.printf("\tUnit Test: %s \n", unitTestMethodName);
        // System.out.printf("\t%s\n", HEADER_02);

        log.info("{}", HEADER_01);
        log.info("Test Case: {}", unitTestClassName);
        log.info("Unit Test: {}", unitTestMethodName);
        log.info("{}", HEADER_02);
    }

    @Override
    public void succeeded(final Description method) {
        resultTest = "PASSED  :-)";
    }

    @Override
    public void failed(final Throwable e, final Description method) {
        resultTest = "FAILED  :-(    >>>>>>>> NOOOOOOOOO !!!!!!!!!!!";
    }

    @Override
    public void finished(final Description method) {
        // System.out.printf("\t%s\n", FOOTER_01);
        // System.out.printf("\t%s \n", resultTest);
        // System.out.printf("\t%s\n", FOOTER_02);

        log.info("{}", FOOTER_01);
        log.info("{}", resultTest);
        log.info("{}\n", FOOTER_02);
    }
}
