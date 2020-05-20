#if canImport(Darwin)
import Darwin

let sys_open = Darwin.open(_: _: _:)
let sys_close = Darwin.close
let sys_write = Darwin.write
let sys_stat = Darwin.fstat
let sys_read = Darwin.read

var sys_errno: Int32 { Darwin.errno }

public typealias stat = Darwin.stat

public typealias mode_t = Darwin.mode_t

let S_IFIFO = Darwin.S_IFIFO
let S_IFREG = Darwin.S_IFREG
let S_IFSOCK = Darwin.S_IFSOCK
let S_IFCHR = Darwin.S_IFCHR

#elseif canImport(Glibc)
import Glibc

let sys_open = Glibc.open(_: _: _:)
let sys_close = Glibc.close
let sys_write = Glibc.write
let sys_stat = Glibc.fstat
let sys_read = Glibc.read

var sys_errno: Int32 { Glibc.errno }

public typealias stat = Glibc.stat

public typealias mode_t = Glibc.mode_t

let S_IFIFO = Glibc.S_IFIFO
let S_IFREG = Glibc.S_IFREG
let S_IFSOCK = Glibc.S_IFSOCK
let S_IFCHR = Glibc.S_IFCHR

#else
#error("Unknown OS")
#endif


