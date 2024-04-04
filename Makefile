.DEFAULT_GOAL := help
HELP-DESCRIPTION-SPACING := 24

APP=spring-petclinic
MVN_EXTRA_OPTS=-DskipTests=true
# -P-otlp,+azure-monitor
AZ_LOCATION=germanywestcentral
AZ_RG=none
AZ_ENV=$(APP)
AZ_APP=$(APP)
APP_IMAGE=ghcr.io/deas/$(APP)-native
APP_TAG=latest
APPLICATIONINSIGHTS_CONNECTION_STRING=none
OTEL_VERSION=2.1.0
OTEL_AGENT=opentelemetry-javaagent-$(OTEL_VERSION).jar
INSIGHTS_VERSION=3.4.19
INSIGHTS_AGENT=applicationinsights-agent-$(INSIGHTS_VERSION).jar
AGENT=$(INSIGHTS_AGENT)
SB_RUN_JVM_ARGS=-Dspring-boot.run.jvmArguments="-javaagent:./$(AGENT)"
# -Dhttps.proxyHost=localhost -Dhttps.proxyPort=3128 -Dcom.sun.net.ssl.checkRevocation=false -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005

# ------- Help ----------------------- #
# Source: https://nedbatchelder.com/blog/201804/makefile_help_target.html

help:  ## Describe available tasks in Makefile
	@grep '^[a-zA-Z]' $(MAKEFILE_LIST) | \
	sort | \
	awk -F ':.*?## ' 'NF==2 {printf "\033[36m  %-$(HELP-DESCRIPTION-SPACING)s\033[0m %s\n", $$1, $$2}'

# java -Dspring.aot.enabled=true -agentlib:native-image-agent=config-output-dir=./native-config  -jar target/spring-petclinic-3.2.0-SNAPSHOT.jar
# mvn clean compile spring-boot:process-aot package
# mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Dhttps.proxyHost=localhost -Dhttps.proxyPort=3128 -Dcom.sun.net.ssl.checkRevocation=false -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005"

.PHONY: build
build: ## Maven build
	mvn $(MVN_EXTRA_OPTS) clean compile package

.PHONY: build-aot
build-aot: ## Maven build ahead-of-time compilation
	export SPRING_PROFILES_ACTIVE=otel && mvn $(MVN_EXTRA_OPTS) clean compile spring-boot:process-aot package

.PHONY: build-native
build-native: ## Maven build application native binary
	export SPRING_PROFILES_ACTIVE=otel && mvn $(MVN_EXTRA_OPTS) -Pnative native:compile

.PHONY: build-native-image
build-native-image: ## Maven build application native image
	mvn -Pnative $(MVN_EXTRA_OPTS) spring-boot:build-image

.PHONY: build-image
build-image: ## Maven build application image image in docker
	mvn $(MVN_EXTRA_OPTS) jib:dockerBuild

.PHONY: az-sp-login
az-sp-login: ## Login with Service Principal - make sure to have proper environment set
	az login --service-principal -u $${ARM_CLIENT_ID} -p $${ARM_CLIENT_SECRET} --tenant $${ARM_TENANT_ID}

#.PHONY: login-registry
#login-registry: ## Authenticate with container registry
#	az acr login --name $(AZ_CR)

#.PHONY: list-repository
#list-repository: ## List application repository tags
#	az acr repository show-tags --name $(AZ_CR) --repository $(APP) --output table

.PHONY: download-agents
download-agents: ## Download OpenTelemetry and Application Insights agents
	curl https://repo1.maven.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/$(OTEL_VERSION)/$(OTEL_AGENT) \
		-o $(OTEL_AGENT)
	curl https://repo1.maven.org/maven2/com/microsoft/azure/applicationinsights-agent/$(INSIGHTS_VERSION)/$(INSIGHTS_AGENT) \
    -o $(INSIGHTS_AGENT)

.PHONY: run-sb
run-sb: ## Run application with Spring Boot Maven Plugin
	mvn spring-boot:run $(SB_RUN_JVM_ARGS)

.PHONY: run-with-agent
run-with-agent: ## Run application with OpenTelemetry or Application Insights agents
	java -javaagent:"./$(AGENT)" -jar target/spring-petclinic-3.2.0-SNAPSHOT.jar
    # export JAVA_TOOL_OPTIONS="-javaagent:$(AGENT)" \
    #     OTEL_SERVICE_NAME=spring-petclinic \
    #     OTEL_TRACES_EXPORTER=logging \
    #     OTEL_METRICS_EXPORTER=logging \
    #     OTEL_LOGS_EXPORTER=logging \
    #     OTEL_METRIC_EXPORT_INTERVAL=15000
    #
    #     OTEL_JAVAAGENT_LOGGING=simple/none/application

.PHONY: az-create-env
az-create-env: ## Create Azure Container App Env
	az containerapp env create \
		--name $(AZ_ENV) \
		--resource-group $(AZ_RG) \
		--location $(AZ_LOCATION)

.PHONY: az-create-app
az-create-app: ## Create Azure Container App Instance (Deploy)
	az containerapp create \
		--name $(AZ_APP) \
		--resource-group $(AZ_RG) \
		--environment $(AZ_ENV) \
		--env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$(APPLICATIONINSIGHTS_CONNECTION_STRING)" "ANOTHER_ONE=xyz" \
		--image $(APP_IMAGE):$(APP_TAG) \
		--target-port 8080 \
		--ingress 'external' \
		--query properties.configuration.ingress.fqdn

# --registry-server $(AZ_CR).azurecr.io \
# ghcr.io

.PHONY: az-update-app
az-update-app: ## Update Azure Container App Instance (Deploy)
	az containerapp update \
		--name $(AZ_APP) \
		--resource-group $(AZ_RG) \
		--image $(APP_IMAGE):$(APP_TAG) \
		--query properties.configuration.ingress.fqdn


# ContainerAppConsoleLogs_CL  / ContainerAppSystemLogs_CL
.PHONY: az-monitor-query-logs
az-monitor-query-logs: ## Query Azure Monitor Logs
	export LOG_WORKSPACE_ID=$$(az monitor log-analytics workspace show --resource-group $(AZ_RG) --workspace-name $(APP) --query customerId -o tsv) && \
		az monitor log-analytics query -w $$LOG_WORKSPACE_ID --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == '$(AZ_CONTAINER_NAME)' | sort by TimeGenerated asc | project Message=Log_s " --query '[].Message'
#  | where ContainerAppName_s == '$(AZ_CONTAINER_NAME)' | project Time=TimeGenerated, AppName=ContainerAppName_s, Revision=RevisionName_s, Container=ContainerName_s, Message=Log_s, LogLevel_s | take 5" --out table
# --query '[].Message'

.PHONY: az-show-logs
az-show-logs: ## Show and Follow logs
	az containerapp logs show \
		--name $(AZ_CONTAINER_NAME) \
		--resource-group $(AZ_RG) \
		--type console \
		--follow

.PHONY: az-delete-app
az-delete-app: ## Delete Azure Container App Instance (Undeploy)
	az containerapp delete --resource-group $(AZ_RG) --name $(AZ_APP)

.PHONY: otel-svc-up
otel-svc-up: ## Start OpenTelemetry Services
	docker compose -f otel-svc/docker-compose.yml --force-recreate --remove-orphans up


.PHONY: signoz-svc-up
signoz-svc-up: ## Start SigNoz Services - UI at port 3301
	docker compose -f signoz-svc/clickhouse-setup/docker-compose.yaml up

.PHONY: aspire-dashboard-svc-up
aspire-dashboard-svc-up: ## Aspire Dashboard UI at port 18888
	docker run --rm -it -p 18888:18888 -p 4317:18889 --name aspire-dashboard mcr.microsoft.com/dotnet/nightly/aspire-dashboard:8.0.0-preview.4

#.PHONY: docker-push
#docker-push: ## Push images to Registry
#	az acr login --name $(AZ_CR)
#	docker push $(APP_IMAGE):latest
#	docker push $(APP_IMAGE):$(APP_TAG)

# .PHONY: otel-start
# otel-start:
#     docker compose up --force-recreate --remove-orphans --detach
#     @echo ""
#     @echo "OpenTelemetry Demo is running."
#     @echo "Go to http://localhost:8080 for the demo UI."
#     @echo "Go to http://localhost:8080/jaeger/ui for the Jaeger UI."
#     @echo "Go to http://localhost:8080/grafana/ for the Grafana UI."
#     @echo "Go to http://localhost:8080/loadgen/ for the Load Generator UI."
#     @echo "Go to http://localhost:8080/feature/ for the Feature Flag UI."
