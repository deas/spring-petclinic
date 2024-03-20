# Spring PetClinic Observability
The Spring PetClinic application modded for OpenTelemetry based observability targetting:

- Spring Native
- Azure Monitor/Insights
- Compatibility with plain Java version
- Span parenting/propagation through http Span(Server) -> Span(Client) (via `okhttp`)

We aim at making `otlp` exporter a first class citizen next to `azure_monitor`.

Try
```shell
make
``` 

to see some workflow entry points.

## Key findings
- Native + Plain Java Compatibility rules out the use of `javaagent` based instrumentation
- Compile time choices happen during `spring-boot:process-aot` phase. Most forward approach to override `application.properties` while keeping compatiblity with Java appears to be using a dedicated profile during that phase. We use `application-otel.properties`.
- `spring-cloud-azure-starter-monitor` is a thin layer on top of `opentelemetry-spring-boot-starter`. Exporters are named `azure_monitor` instead of `otlp`.
- As of `spring-cloud-azure-starter-monitor:1.0.0-beta.4`, there appears to be a tight coupling to specific versions of `opentelemetry-bom` and/or `opentelemetry-instrumentation-bom-alpha`. Bumping to `1.35` / `2.2.0-alpha` failed falling back to `opentelemetry-spring-boot-starter` behaviour.
- `GlobalOpenTelemetry.get()` does not return the expected instance. We should get it via `@AutoWired`.
- `WebMvcTelemetryProducingFilter` from `spring-webmvc` is does most of what we want out of the box. Except for providing us with span name updates for anything not based on `@RequestMapping`. We end up with `GET` instead of `GET /foo`.

## TODO
- [ ] Improve switch `azure_monitor` <-> `otlp` w/o changing the compile time dependency

## References
- Native Azure Container Apps with Insights : [Monitor your Spring Boot native image application on Azure](https://devblogs.microsoft.com/java/monitor-your-spring-boot-native-image-application-on-azure/)
- Bare [OpenTelemetry Spring Native](https://github.com/open-telemetry/opentelemetry-java-examples/tree/main/spring-native)

- [azure-sdk-for-java/sdk/spring/spring-cloud-azure-starter-monitor/](https://github.com/Azure/azure-sdk-for-java/tree/main/sdk/spring/spring-cloud-azure-starter-monitor)
- [Configuring with Environment Variables](https://opentelemetry.io/docs/languages/java/automatic/configuration/#configuring-with-environment-variables)
- [OpenTelemetry SDK Autoconfigure](https://github.com/open-telemetry/opentelemetry-java/blob/main/sdk-extensions/autoconfigure/README.md)
- [Spring Boot Automatic instrumentation](https://opentelemetry.io/docs/languages/java/automatic/spring-boot/#automatic-instrumentation)
- [instrumentation/spring/spring-boot-autoconfigure/src/main/java/io/opentelemetry/instrumentation/spring/autoconfigure](https://github.com/open-telemetry/opentelemetry-java-instrumentation/tree/main/instrumentation/spring/spring-boot-autoconfigure/src/main/java/io/opentelemetry/instrumentation/spring/autoconfigure)
[org.springframework.boot.autoconfigure.AutoConfiguration.imports](https://github.com/Azure/azure-sdk-for-java/blob/main/sdk/spring/spring-cloud-azure-starter-monitor/src/main/resources/META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports)
- [Set up and observe a Spring Boot application with Grafana Cloud, Prometheus, and OpenTelemetry](https://grafana.com/blog/2022/04/26/set-up-and-observe-a-spring-boot-application-with-grafana-cloud-prometheus-and-opentelemetry/)
- [Send logs to Loki with Loki receiver](https://grafana.com/docs/opentelemetry/collector/send-logs-to-loki/loki-receiver/)/[Support receiving logs in Loki using OpenTelemetry OTLP](https://github.com/grafana/loki/issues/5346)
