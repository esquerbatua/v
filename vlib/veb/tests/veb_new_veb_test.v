// vtest build: !sanitized_job?
module main

import os
import time
import net.http
import veb

const test_port_new_veb = 18891

// Test server application for new_veb backend testing
struct TestApp {
mut:
	request_count shared int
}

struct TestContext {
	veb.Context
}

pub fn (mut app TestApp) index(mut ctx TestContext) veb.Result {
	lock app.request_count {
		app.request_count++
	}
	return ctx.text('Hello from new_veb')
}

pub fn (mut app TestApp) echo(mut ctx TestContext, msg string) veb.Result {
	return ctx.text('Echo: ${msg}')
}

pub fn (mut app TestApp) json_test(mut ctx TestContext) veb.Result {
	return ctx.json({
		'status':  'ok'
		'backend': 'new_veb'
	})
}

@[post]
pub fn (mut app TestApp) post_data(mut ctx TestContext) veb.Result {
	data := ctx.req.data
	return ctx.text('Received: ${data}')
}

pub fn (mut app TestApp) counter(mut ctx TestContext) veb.Result {
	count := rlock app.request_count {
		app.request_count
	}
	return ctx.text('Count: ${count}')
}

// Test that new_veb backend works with basic requests
fn test_new_veb_basic_request() {
	$if !new_veb ? {
		eprintln('Skipping new_veb test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb}/', '') or {
		assert false, 'Failed to create request: ${err}'
		return
	}
	client.read_timeout = 5 * time.second

	response := client.do() or {
		assert false, 'Request failed: ${err}'
		return
	}

	assert response.status_code == 200, 'Expected 200, got ${response.status_code}'
	assert response.body == 'Hello from new_veb', 'Expected "Hello from new_veb", got "${response.body}"'
}

// Test concurrent requests to new_veb backend
fn test_new_veb_concurrent_requests() {
	$if !new_veb ? {
		eprintln('Skipping new_veb concurrent test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb + 1
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	num_requests := 20
	mut threads := []thread{}
	mut success_count := shared int
	(0)

	for i in 0 .. num_requests {
		threads << spawn fn [mut success_count, i] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 1}/',
				'') or { return }
			client.read_timeout = 5 * time.second

			response := client.do() or { return }

			if response.status_code == 200 && response.body == 'Hello from new_veb' {
				lock success_count {
					success_count++
				}
			}
		}()
	}

	for t in threads {
		t.wait()
	}

	final_count := rlock success_count {
		success_count
	}

	assert final_count == num_requests, 'Expected ${num_requests} successful responses, got ${final_count}'
}

// Test new_veb with different HTTP methods
fn test_new_veb_different_methods() {
	$if !new_veb ? {
		eprintln('Skipping new_veb methods test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb + 2
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	// Test GET
	mut client_get := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 2}/',
		'') or {
		assert false, 'Failed to create GET request'
		return
	}
	client_get.read_timeout = 5 * time.second
	response_get := client_get.do() or {
		assert false, 'GET request failed'
		return
	}
	assert response_get.status_code == 200

	// Test POST
	mut client_post := http.new_request(.post, 'http://127.0.0.1:${test_port_new_veb + 2}/post_data',
		'test data') or {
		assert false, 'Failed to create POST request'
		return
	}
	client_post.read_timeout = 5 * time.second
	response_post := client_post.do() or {
		assert false, 'POST request failed'
		return
	}
	assert response_post.status_code == 200
	assert response_post.body == 'Received: test data'
}

// Test new_veb with JSON responses
fn test_new_veb_json_response() {
	$if !new_veb ? {
		eprintln('Skipping new_veb JSON test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb + 3
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 3}/json_test',
		'') or {
		assert false, 'Failed to create request'
		return
	}
	client.read_timeout = 5 * time.second

	response := client.do() or {
		assert false, 'Request failed'
		return
	}

	assert response.status_code == 200
	assert response.body.contains('"status":"ok"') || response.body.contains('"status": "ok"')
	assert response.body.contains('"backend":"new_veb"')
		|| response.body.contains('"backend": "new_veb"')
}

// Test new_veb with route parameters
fn test_new_veb_route_parameters() {
	$if !new_veb ? {
		eprintln('Skipping new_veb route params test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb + 4
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	test_message := 'hello_world'
	mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 4}/echo?msg=${test_message}',
		'') or {
		assert false, 'Failed to create request'
		return
	}
	client.read_timeout = 5 * time.second

	response := client.do() or {
		assert false, 'Request failed'
		return
	}

	assert response.status_code == 200
	assert response.body == 'Echo: ${test_message}'
}

// Test that request counter works correctly with concurrency
fn test_new_veb_request_counter() {
	$if !new_veb ? {
		eprintln('Skipping new_veb counter test - compile with -d new_veb')
		return
	}

	mut app := &TestApp{}
	spawn veb.run_at[TestApp, TestContext](mut app,
		port:               test_port_new_veb + 5
		family:             .ip
		timeout_in_seconds: 5
	)

	time.sleep(1000 * time.millisecond)

	// Send several requests to increment counter
	num_requests := 15
	mut threads := []thread{}

	for i in 0 .. num_requests {
		threads << spawn fn [i] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 5}/',
				'') or { return }
			client.read_timeout = 5 * time.second
			client.do() or { return }
		}()
	}

	for t in threads {
		t.wait()
	}

	time.sleep(500 * time.millisecond)

	// Check counter
	mut client := http.new_request(.get, 'http://127.0.0.1:${test_port_new_veb + 5}/counter',
		'') or {
		assert false, 'Failed to create counter request'
		return
	}
	client.read_timeout = 5 * time.second

	response := client.do() or {
		assert false, 'Counter request failed'
		return
	}

	assert response.status_code == 200
	assert response.body == 'Count: ${num_requests}', 'Expected "Count: ${num_requests}", got "${response.body}"'
}
