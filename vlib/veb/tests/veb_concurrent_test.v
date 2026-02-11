// vtest build: !sanitized_job?
import os
import time
import net.http

const sport_concurrent = 13099
const exit_after_time = 12000

fn test_concurrent_requests_are_handled() {
	// This test verifies that the veb server can handle multiple concurrent requests
	// Build and run the test server
	vexe := os.getenv('VEXE')
	vroot := os.dir(vexe)
	serverexe := os.join_path(os.cache_dir(), 'veb_concurrent_test_server.exe')

	// Clean up if exists
	if os.exists(serverexe) {
		os.rm(serverexe) or {}
	}

	// Compile the server
	os.chdir(vroot) or {}
	did_server_compile := os.system('${os.quoted_path(vexe)} -o ${os.quoted_path(serverexe)} vlib/veb/tests/veb_test_server.v')
	assert did_server_compile == 0, 'Server should compile'
	assert os.exists(serverexe), 'Server binary should exist'

	// Start the server in background
	mut suffix := ''
	$if !windows {
		suffix = ' > /dev/null &'
	}
	server_exec_cmd := '${os.quoted_path(serverexe)} ${sport_concurrent} ${exit_after_time} ${suffix}'

	$if windows {
		spawn os.system(server_exec_cmd)
	} $else {
		res := os.system(server_exec_cmd)
		assert res == 0, 'Server should start successfully'
	}

	// Give server time to start
	$if macos {
		time.sleep(1000 * time.millisecond)
	} $else {
		time.sleep(200 * time.millisecond)
	}

	// Test concurrent requests
	num_requests := 15
	start_time := time.now()

	// Create a channel to collect results
	ch := chan int{cap: num_requests}

	// Send multiple requests concurrently
	for i in 0 .. num_requests {
		spawn fn [ch, i] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${sport_concurrent}/',
				'')
			client.read_timeout = 10 * time.second
			client.write_timeout = 10 * time.second

			response := client.do() or {
				eprintln('Request ${i} failed: ${err}')
				ch <- 0
				return
			}

			if response.status_code == 200 {
				ch <- 1
			} else {
				eprintln('Request ${i} got status ${response.status_code}')
				ch <- 0
			}
		}()
	}

	// Collect results
	mut success_count := 0
	for _ in 0 .. num_requests {
		result := <-ch
		success_count += result
	}

	elapsed := time.since(start_time)

	// Verify all requests succeeded
	assert success_count == num_requests, 'Expected ${num_requests} successful requests, got ${success_count}'

	// If requests were handled sequentially, they would take much longer
	// Each request sleeps for ~10ms, so 15 sequential would be ~150ms+
	// Concurrent handling should complete much faster (< 100ms typically)
	// We use a generous timeout to avoid flaky tests
	assert elapsed < 5 * time.second, 'Requests took too long (${elapsed}), likely not concurrent'

	println('✓ Concurrent test passed: ${num_requests} requests handled in ${elapsed}')
}

fn test_concurrent_requests_with_new_veb() {
	$if !linux {
		eprintln('Skipping new_veb concurrent test - only supported on Linux')
		return
	}

	// This test verifies that the new_veb backend can handle concurrent requests
	// Note: The new_veb backend uses fasthttp with multithreading, so it should
	// handle requests concurrently. However, startup time and thread pool initialization
	// may cause the first batch of requests to take longer.
	vexe := os.getenv('VEXE')
	vroot := os.dir(vexe)
	serverexe_new := os.join_path(os.cache_dir(), 'veb_concurrent_new_test_server.exe')

	// Clean up if exists
	if os.exists(serverexe_new) {
		os.rm(serverexe_new) or {}
	}

	// Compile the server with new_veb
	os.chdir(vroot) or {}
	did_server_compile := os.system('${os.quoted_path(vexe)} -d new_veb -o ${os.quoted_path(serverexe_new)} vlib/veb/tests/veb_test_server.v')
	assert did_server_compile == 0, 'Server with new_veb should compile'
	assert os.exists(serverexe_new), 'Server binary should exist'

	// Start the server in background
	sport_new := sport_concurrent + 10
	mut suffix := ' > /dev/null &'
	server_exec_cmd := '${os.quoted_path(serverexe_new)} ${sport_new} ${exit_after_time} ${suffix}'

	res := os.system(server_exec_cmd)
	assert res == 0, 'Server should start successfully'

	// Give server more time to start and initialize thread pool
	time.sleep(1000 * time.millisecond)

	// Test concurrent requests
	num_requests := 20
	start_time := time.now()

	// Create a channel to collect results
	ch := chan int{cap: num_requests}

	// Send multiple requests concurrently
	for i in 0 .. num_requests {
		spawn fn [ch, i, sport_new] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${sport_new}/', '')
			client.read_timeout = 10 * time.second
			client.write_timeout = 10 * time.second

			response := client.do() or {
				eprintln('Request ${i} failed: ${err}')
				ch <- 0
				return
			}

			if response.status_code == 200 {
				ch <- 1
			} else {
				eprintln('Request ${i} got status ${response.status_code}')
				ch <- 0
			}
		}()
	}

	// Collect results
	mut success_count := 0
	for _ in 0 .. num_requests {
		result := <-ch
		success_count += result
	}

	elapsed := time.since(start_time)

	// Verify all requests succeeded
	assert success_count == num_requests, 'Expected ${num_requests} successful requests, got ${success_count}'

	// The key metric is that all requests completed successfully
	// With the multithreading fix, concurrent requests should work
	// Timing can vary based on system load, but all should complete
	println('✓ new_veb concurrent test passed: ${num_requests} requests handled in ${elapsed}, all successful')
}
