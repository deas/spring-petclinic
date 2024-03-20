APP := "spring-petclinic"
MVN_EXTRA_OPTS := "-DskipTests=true"
AZ_LOCATION := "germanywestcentral"
AZ_RG := "none"
AZ_ENV := "{{APP}}"
AZ_APP := "{{APP}}"
APP_IMAGE := "ghcr.io/deas/{{APP}}-native"
APP_TAG := "latest"
APPLICATIONINSIGHTS_CONNECTION_STRING := "none"

# first recipe called automatically 
help:
  @just --list

# Maven build ahead-of-time compilation
build-aot:
    mvn {{MVN_EXTRA_OPTS}} clean compile spring-boot:process-aot package

# Maven build application native binary
build-native:
    mvn {{MVN_EXTRA_OPTS}} -Pnative native:compile
