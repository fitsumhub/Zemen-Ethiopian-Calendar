import 'dart:typed_data';

import 'read_local_bytes_stub.dart'
    if (dart.library.io) 'read_local_bytes_io.dart' as impl;

Future<Uint8List?> readLocalFileBytes(String path) =>
    impl.readLocalFileBytes(path);
