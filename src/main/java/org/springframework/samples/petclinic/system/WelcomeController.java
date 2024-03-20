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

package org.springframework.samples.petclinic.system;

import java.io.IOException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.instrumentation.okhttp.v3_0.OkHttpTelemetry;
import io.opentelemetry.api.GlobalOpenTelemetry;
import okhttp3.Call;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

@Controller
class WelcomeController {

	@Autowired
	OpenTelemetry openTelemetry;

	@GetMapping("/")
	public String welcome() {
		// var url = "http://localhost:1234";
		var url = "https://www.google.com";
		httpGet(openTelemetry, url);
		return "welcome";
	}

	// Use this Call.Factory implementation for making standard http client calls.
	public Call.Factory createTracedClient(OpenTelemetry openTelemetry) {
		return OkHttpTelemetry.builder(openTelemetry).build().newCallFactory(createClient());
	}

	// your configuration of the OkHttpClient goes here:
	private OkHttpClient createClient() {
		return new OkHttpClient.Builder().build();
	}

	void httpGet(OpenTelemetry openTelemetry, String url) {
		Call.Factory client = createTracedClient(openTelemetry);
		Request request = new Request.Builder().url(url).build();
		Call call = client.newCall(request);
		try {
			Response response = call.execute();
		}
		catch (IOException e) {
			throw new RuntimeException(e);
		}
	}

}
