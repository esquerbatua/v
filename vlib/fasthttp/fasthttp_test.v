module fasthttp

import os

const fasthttp_example_exe = os.join_path(os.cache_dir(), 'fasthttp_example_test.exe')

fn testsuite_begin() {
	// Clean up old example binary if it exists
	if os.exists(fasthttp_example_exe) {
		os.rm(fasthttp_example_exe) or {}
	}
}

fn test_fasthttp_example_compiles() {
	vexe := os.getenv('VEXE')
	vroot := os.dir(vexe)

	// Build the fasthttp example
	build_result := os.system('${os.quoted_path(vexe)} -o ${os.quoted_path(fasthttp_example_exe)} ${os.join_path(vroot,
		'examples', 'fasthttp')}')
	assert build_result == 0, 'fasthttp example failed to compile'
	assert os.exists(fasthttp_example_exe), 'fasthttp example binary not found after build'
}

fn test_new_server() {
	handler := fn (req HttpRequest) !HttpResponse {
		return HttpResponse{
			content: 'HTTP/1.1 200 OK\r\n\r\nHello'.bytes()
		}
	}

	server := new_server(ServerConfig{
		port:    8080
		handler: handler
	}) or {
		assert false, 'Failed to create server: ${err}'
		return
	}

	assert server.port == 8080
}

fn test_server_ipv4_ipv6_binding() {
	// Test IPv4 binding
	handler := fn (req HttpRequest) !HttpResponse {
		return HttpResponse{
			content: 'HTTP/1.1 200 OK\r\n\r\nIPv4 test'.bytes()
		}
	}

	server_ipv4 := new_server(ServerConfig{
		family:  .ip
		port:    8081
		handler: handler
	}) or {
		assert false, 'Failed to create IPv4 server: ${err}'
		return
	}

	// Test IPv6 binding
	server_ipv6 := new_server(ServerConfig{
		family:  .ip6
		port:    8082
		handler: handler
	}) or {
		assert false, 'Failed to create IPv6 server: ${err}'
		return
	}

	// Verify both servers were created successfully
	// Note: family field is not exported, so we can't directly test it
	assert server_ipv4.port == 8081
	assert server_ipv6.port == 8082
}

// Test large request buffer handling
fn test_large_request_buffer() {
	handler := fn (req HttpRequest) !HttpResponse {
		return HttpResponse{
			content: 'HTTP/1.1 200 OK\r\n\r\nOK'.bytes()
		}
	}

	// Test with large buffer size
	server := new_server(ServerConfig{
		port:                    8083
		handler:                 handler
		max_request_buffer_size: 16384
	}) or {
		assert false, 'Failed to create server with large buffer: ${err}'
		return
	}

	assert server.max_request_buffer_size == 16384
}

// Test request with query parameters
fn test_parse_request_with_query() {
	request := 'GET /search?q=test&page=1 HTTP/1.1\r\n'.bytes()
	req := decode_http_request(request) or {
		assert false, 'Failed to parse request with query: ${err}'
		return
	}

	path := req.buffer[req.path.start..req.path.start + req.path.len].bytestr()
	assert path == '/search?q=test&page=1'
}

// Test different HTTP methods
fn test_parse_different_http_methods() {
	methods := ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS']

	for method in methods {
		request := '${method} /test HTTP/1.1\r\n'.bytes()
		req := decode_http_request(request) or {
			assert false, 'Failed to parse ${method} request: ${err}'
			continue
		}

		parsed_method := req.buffer[req.method.start..req.method.start + req.method.len].bytestr()
		assert parsed_method == method, 'Expected ${method}, got ${parsed_method}'
	}
}

// Test request with special characters in path
fn test_parse_request_with_special_chars() {
	request := 'GET /path%20with%20spaces HTTP/1.1\r\n'.bytes()
	req := decode_http_request(request) or {
		assert false, 'Failed to parse request with encoded chars: ${err}'
		return
	}

	path := req.buffer[req.path.start..req.path.start + req.path.len].bytestr()
	assert path == '/path%20with%20spaces'
}

// Test very long path
fn test_parse_request_with_long_path() {
	long_path := '/' + 'a'.repeat(1000)
	request := 'GET ${long_path} HTTP/1.1\r\n'.bytes()
	req := decode_http_request(request) or {
		assert false, 'Failed to parse request with long path: ${err}'
		return
	}

	path := req.buffer[req.path.start..req.path.start + req.path.len].bytestr()
	assert path == long_path
	assert path.len == 1001
}

// Test request with multiple headers
fn test_parse_request_multiple_headers() {
	request := 'GET / HTTP/1.1\r\n' + 'Host: example.com\r\n' + 'Accept: text/html\r\n' +
		'Accept-Encoding: gzip\r\n' + 'Connection: keep-alive\r\n' + '\r\n'
	req := decode_http_request(request.bytes()) or {
		assert false, 'Failed to parse request with multiple headers: ${err}'
		return
	}

	headers := req.buffer[req.header_fields.start..req.header_fields.start + req.header_fields.len].bytestr()
	assert headers.contains('Host: example.com')
	assert headers.contains('Accept: text/html')
	assert headers.contains('Accept-Encoding: gzip')
	assert headers.contains('Connection: keep-alive')
}
