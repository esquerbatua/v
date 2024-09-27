module picoev

// maximum number of file descriptors that can be managed
pub const max_fds = 1024

// maximum size of the event queue
pub const max_queue = 4096

// event for incoming data ready to be read on a socket
pub const picoev_read = 1

// event for socket ready for writing
pub const picoev_write = 2

// event read/write
pub const picoev_readwrite = 3

// event indicating a timeout has occurred
pub const picoev_timeout = 4

// flag for adding a file descriptor to the event loop
pub const picoev_add = 0x40000000

// flag for removing a file descriptor from the event loop
pub const picoev_del = 0x20000000
