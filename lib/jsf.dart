/*
 * Copyright (C) 2025 moluopro. All rights reserved.
 * Github: https://github.com/moluopro
 */

export 'src/runtime_ffi.dart'
    if (dart.library.js_interop) 'src/runtime_web.dart';
