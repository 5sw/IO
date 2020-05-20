#if canImport(Darwin)
import Darwin

let sys_open = Darwin.open(_: _: _:)
let sys_close = Darwin.close
let sys_write = Darwin.write
let sys_stat = Darwin.fstat
let sys_read = Darwin.read

var sys_errno: Int32 { Darwin.errno }

public typealias stat = Darwin.stat

#elseif canImport(Glibc)
import Glibc

let sys_open = Glibc.open(_: _: _:)
let sys_close = Glibc.close
let sys_write = Glibc.write
let sys_stat = Glibc.fstat
let sys_read = Glibc.read

var sys_errno: Int32 { Glibc.errno }

public typealias stat = Glibc.stat

#else
#error("Unknown OS")
#endif
