/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

package de.contentreich.opentelemetry.instrumentation.spring.web;

import java.util.Collections;

import io.opentelemetry.context.propagation.TextMapGetter;
import jakarta.servlet.http.HttpServletRequest;

enum JakartaHttpServletRequestGetter implements TextMapGetter<HttpServletRequest> {

	INSTANCE;

	@Override
	public Iterable<String> keys(HttpServletRequest carrier) {
		return Collections.list(carrier.getHeaderNames());
	}

	@Override
	public String get(HttpServletRequest carrier, String key) {
		return carrier.getHeader(key);
	}

}
