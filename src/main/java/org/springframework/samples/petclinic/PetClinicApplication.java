/*
 * Copyright 2012-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.springframework.samples.petclinic;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
// import org.springframework.context.annotation.Conditional;
import org.springframework.context.annotation.ImportRuntimeHints;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.servlet.DispatcherServlet;
import jakarta.servlet.Filter;

import de.contentreich.opentelemetry.instrumentation.spring.web.SpringWebMvcTelemetry;
import io.opentelemetry.api.OpenTelemetry;
// import io.opentelemetry.instrumentation.spring.autoconfigure.internal.SdkEnabled;

/**
 * PetClinic Spring Boot Application.
 *
 * @author Dave Syer
 *
 */
@SpringBootApplication
@ImportRuntimeHints(PetClinicRuntimeHints.class)
public class PetClinicApplication {

	public static void main(String[] args) {
		SpringApplication.run(PetClinicApplication.class, args);
	}

	// @ConditionalOnBean(OpenTelemetry.class)
	// @ConditionalOnClass({ Filter.class, OncePerRequestFilter.class,
	// DispatcherServlet.class })
	@ConditionalOnExpression("'${otel.instrumentation.spring-webmvc.enabled}'=='false' && '${contentreich.otel.instrumentation.spring.enabled}'=='true'")
	// @Conditional(SdkEnabled.class)
	@Bean
	Filter otelWebMvcFilter(OpenTelemetry openTelemetry) {
		return SpringWebMvcTelemetry.create(openTelemetry).createServletFilter();
	}

}
