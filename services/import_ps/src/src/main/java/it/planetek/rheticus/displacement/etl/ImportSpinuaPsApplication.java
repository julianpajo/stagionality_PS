package it.planetek.rheticus.displacement.etl;

import org.springframework.boot.Banner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.ImportResource;


@SpringBootApplication
@EnableAutoConfiguration(exclude = {DataSourceAutoConfiguration.class})
@ImportResource("classpath:jobs/*.xml")
public class ImportSpinuaPsApplication {

    public static void main(String[] args) {
        SpringApplication bootApp = new SpringApplication(ImportSpinuaPsApplication.class);
        bootApp.setBannerMode(Banner.Mode.CONSOLE);
        bootApp.setLogStartupInfo(false);
        ApplicationContext context = bootApp.run(args);
        int exitCode = SpringApplication.exit(context);
        System.exit(exitCode);
    }
}
