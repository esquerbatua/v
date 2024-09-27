module veb

import net.http

// A type which doesn't get filtered inside templates
pub type RawHtml = string

// A dummy structure that returns from routes to indicate that you actually sent something to a user
@[noinit]
pub struct Result {}

struct Route {
	methods []http.Method
	path    string
	host    string
mut:
	middlewares       []voidptr
	after_middlewares []voidptr
}

@[params]
pub struct RunParams {
pub:
	// use `family: .ip, host: 'localhost'` when you want it to bind only to 127.0.0.1
	family               net.AddrFamily = .ip6
	host                 string
	port                 int  = 8080
	show_startup_message bool = true
	timeout_in_seconds   int  = 30
	num_loops            int  = 1
}

struct FileResponse {
pub mut:
	open              bool
	file              os.File
	total             i64
	pos               i64
	should_close_conn bool
}

struct StringResponse {
pub mut:
	open              bool
	str               string
	pos               i64
	should_close_conn bool
}

// EV context
struct RequestParams {
	global_app         voidptr
	controllers        []&ControllerPath
	routes             &map[string]Route
	timeout_in_seconds int
mut:
	// request body buffer
	buf &u8 = unsafe { nil }
	// idx keeps track of how much of the request body has been read
	// for each incomplete request, see `handle_conn`
	idx                 []int
	incomplete_requests []http.Request
	file_responses      []FileResponse
	string_responses    []StringResponse
}

interface BeforeAcceptApp {
mut:
	before_accept_loop()
}
