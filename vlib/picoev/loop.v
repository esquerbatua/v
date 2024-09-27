module picoev

// create_loop - Creates a new Event Loop
pub fn (mut pv Picoev) create_loop(id int) !&LoopType {
	// epoll on linux
	// kqueue on macos and bsd
	// select on windows and others
	$if linux {
		return create_epoll_loop(id) or { panic(err) }
	} $else $if freebsd || macos {
		return create_kqueue_loop(id) or { panic(err) }
	} $else {
		return create_select_loop(id) or { panic(err) }
	}
	return unsafe { nil }
}

fn (mut pv Picoev) loop_once(mut loop LoopType, max_wait_in_sec int) int {
	loop.now = get_time()

	if pv.poll_once(loop, max_wait_in_sec) != 0 {
		eprintln('Error during poll_once')
		return -1
	}

	if max_wait_in_sec != 0 {
		loop.now = get_time() // Update loop start time again if waiting occurred
	} else {
		// If no waiting, skip timeout handling for potential performance optimization
		return 0
	}

	pv.handle_timeout()
	return 0
}
