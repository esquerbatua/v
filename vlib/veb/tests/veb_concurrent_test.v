// vtest build: !sanitized_job?
import os
import time
import net.http

const sport_concurrent = 13099
const exit_after_time = 30000 // Increased timeout for slow requests

fn test_concurrent_requests_are_handled_truly_concurrent() {
	// This test verifies that requests are ACTUALLY handled concurrently
	// by using a /slow endpoint that takes 1 second per request
	// NOTE: picoev backend is single-threaded, so this test will show sequential behavior
	// This is expected and correct for the default backend
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

	// Get number of CPU cores
	num_cores := get_num_cores()
	println('System has ${num_cores} CPU cores')

	// Test with fewer requests since picoev is single-threaded
	num_requests := 4
	start_time := time.now()

	// Create a channel to collect results
	ch := chan int{cap: num_requests}

	// Send multiple requests concurrently to /slow endpoint
	for i in 0 .. num_requests {
		spawn fn [ch, i] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${sport_concurrent}/slow',
				'')
			client.read_timeout = 15 * time.second
			client.write_timeout = 15 * time.second

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
	elapsed_seconds := elapsed.seconds()

	// Verify all requests succeeded
	assert success_count == num_requests, 'Expected ${num_requests} successful requests, got ${success_count}'

	// Calculate expected times
	sequential_time := f64(num_requests) // seconds if sequential (1s per request)

	println('Results for default backend (picoev - single-threaded):')
	println('  Requests: ${num_requests}')
	println('  CPU cores: ${num_cores}')
	println('  Elapsed time: ${elapsed_seconds:.2f} seconds')
	println('  Expected (sequential): ~${sequential_time:.0f} seconds')

	// picoev is single-threaded, so we expect sequential processing
	// Verify it takes approximately sequential time (with some tolerance)
	assert elapsed_seconds >= sequential_time * 0.8, 'Took ${elapsed_seconds:.2f}s, expected ~${sequential_time:.0f}s for sequential processing'
	assert elapsed_seconds < sequential_time * 1.3, 'Took ${elapsed_seconds:.2f}s, should be close to ${sequential_time:.0f}s for sequential processing'

	println('✓ Test passed: picoev correctly handles ${num_requests} requests sequentially in ${elapsed_seconds:.2f}s')
}

fn test_concurrent_requests_with_new_veb_truly_concurrent() {
	$if !linux {
		eprintln('Skipping new_veb concurrent test - only supported on Linux')
		return
	}

	// This test verifies new_veb backend handles requests concurrently with fasthttp
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

	// Give server time to start and initialize thread pool
	time.sleep(1000 * time.millisecond)

	// Get number of CPU cores
	num_cores := get_num_cores()
	println('System has ${num_cores} CPU cores')

	// Test with num_cores * 2 requests to see clear benefit of multithreading
	num_requests := num_cores * 2
	start_time := time.now()

	// Create a channel to collect results
	ch := chan int{cap: num_requests}

	// Send multiple requests concurrently to /slow endpoint
	for i in 0 .. num_requests {
		spawn fn [ch, i, sport_new] () {
			mut client := http.new_request(.get, 'http://127.0.0.1:${sport_new}/slow',
				'')
			client.read_timeout = 15 * time.second
			client.write_timeout = 15 * time.second

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
	elapsed_seconds := elapsed.seconds()

	// Verify all requests succeeded
	assert success_count == num_requests, 'Expected ${num_requests} successful requests, got ${success_count}'

	// Calculate expected times
	sequential_time := f64(num_requests) // seconds if sequential
	concurrent_time := f64((num_requests + num_cores - 1) / num_cores) // seconds if concurrent

	// With multithreading, should be MUCH faster than sequential
	// Expected: ~(num_requests / num_cores) seconds
	max_acceptable_time := concurrent_time * 1.5 // Allow 50% overhead

	println('Results for new_veb backend (fasthttp multithreading):')
	println('  Requests: ${num_requests}')
	println('  CPU cores: ${num_cores}')
	println('  Elapsed time: ${elapsed_seconds:.2f} seconds')
	println('  Sequential would take: ${sequential_time:.0f} seconds')
	println('  Concurrent should take: ~${concurrent_time:.0f} seconds')
	println('  Max acceptable: ${max_acceptable_time:.1f} seconds')

	// THIS IS THE KEY TEST: Verify concurrency by checking time is much less than sequential
	// With the multithreading fix, 8 requests on 4 cores should take ~2s, not 8s
	assert elapsed_seconds < max_acceptable_time, 'Took ${elapsed_seconds:.2f}s, expected < ${max_acceptable_time:.1f}s (concurrent processing!)'
	assert elapsed_seconds < sequential_time * 0.5, 'Took ${elapsed_seconds:.2f}s, should be much less than ${sequential_time:.0f}s (proves concurrent processing!)'

	println('✓ new_veb concurrent test passed: ${num_requests} requests handled CONCURRENTLY in ${elapsed_seconds:.2f}s')
	println('  (Sequential would have taken ${sequential_time:.0f}s - this proves multithreading works!)')
}

// Helper function to get number of CPU cores
fn get_num_cores() int {
	$if windows {
		// Windows
		num_cores_str := os.getenv('NUMBER_OF_PROCESSORS')
		return num_cores_str.int()
	} $else {
		// Linux/Mac - use nproc or fallback
		result := os.execute('nproc')
		if result.exit_code == 0 {
			return result.output.trim_space().int()
		}
		// Fallback: try sysctl for macOS
		result2 := os.execute('sysctl -n hw.ncpu')
		if result2.exit_code == 0 {
			return result2.output.trim_space().int()
		}
		// Default to 2 if we can't detect
		return 2
	}
}
