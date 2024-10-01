module net

#include <errno.h>
#include <sys/types.h>
$if windows {
	#include <winsock2.h>
	#include <ws2tcpip.h>
} $else $if freebsd || macos {
	#include <sys/socket.h>
	#include <netinet/in.h>
	#include <netinet/tcp.h>
} $else {
	#include <netinet/tcp.h>
	#include <sys/resource.h>
	#include <sys/select.h>
}

pub enum SocketOption {
	// TODO: SO_ACCEPT_CONN is not here because windows doesn't support it
	// and there is no easy way to define it
	broadcast        = C.SO_BROADCAST
	debug            = C.SO_DEBUG
	dont_route       = C.SO_DONTROUTE
	error            = C.SO_ERROR
	ip_proto_ipv6    = C.IPPROTO_IPV6
	ipv6_only        = C.IPV6_V6ONLY
	keep_alive       = C.SO_KEEPALIVE
	linger           = C.SO_LINGER
	oob_inline       = C.SO_OOBINLINE
	receive_buf_size = C.SO_RCVBUF
	receive_low_size = C.SO_RCVLOWAT
	receive_timeout  = C.SO_RCVTIMEO
	reuse_addr       = C.SO_REUSEADDR
	reuse_port       = C.SO_REUSEPORT // TODO make it work in windows
	send_buf_size    = C.SO_SNDBUF
	send_low_size    = C.SO_SNDLOWAT
	send_timeout     = C.SO_SNDTIMEO
	socket_type      = C.SO_TYPE
	tcp_defer_accept = C.TCP_DEFER_ACCEPT // TODO make it work in os != linux
	tcp_fastopen     = C.TCP_FASTOPEN     // TODO make it work in windows
	tcp_quickack     = C.TCP_QUICKACK     // TODO make it work in os != linux
}

pub const opts_bool = [SocketOption.broadcast, .debug, .dont_route, .error, .keep_alive, .oob_inline]

pub const opts_int = [
	SocketOption.receive_buf_size,
	.receive_low_size,
	.receive_timeout,
	.send_buf_size,
	.send_low_size,
	.send_timeout,
]

pub const opts_can_set = [
	SocketOption.broadcast,
	.debug,
	.dont_route,
	.keep_alive,
	.linger,
	.oob_inline,
	.receive_buf_size,
	.receive_low_size,
	.receive_timeout,
	.send_buf_size,
	.send_low_size,
	.send_timeout,
	.ipv6_only,
]
