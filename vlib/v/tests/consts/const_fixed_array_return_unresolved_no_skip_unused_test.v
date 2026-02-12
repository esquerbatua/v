import os

const vexe = @VEXE

fn test_no_skip_unused_with_forward_const_reference() {
	test_dir := os.join_path(os.vtmp_dir(), 'v', 'test_no_skip_unused')
	os.mkdir_all(test_dir) or {}
	defer {
		os.rmdir_all(test_dir) or {}
	}

	test_file := os.join_path(test_dir, 'test.v')
	os.write_file(test_file, 'fn get_chunkmap_at_coords(mapp []Chunk) [chunk_size][chunk_size]u64 {
	return mapp[0].id_map
}

const chunk_size = 100

struct Chunk {
	id_map [chunk_size][chunk_size]u64
}

fn test_main() {
	t := Chunk{}
	assert t.id_map[0].len == 100
	assert t.id_map.len == 100
}
') or {
		panic(err)
	}

	// Test compilation with -no-skip-unused flag
	result := os.execute('${os.quoted_path(vexe)} -no-skip-unused ${os.quoted_path(test_file)}')
	assert result.exit_code == 0, 'compilation with -no-skip-unused failed:\n${result.output}'
}
