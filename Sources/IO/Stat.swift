extension stat {
    var isRegular: Bool {
        return hasMode(S_IFREG)
    }

    var isSocket: Bool {
        return hasMode(S_IFSOCK)
    }

    var isCharacterSpecial: Bool {
        return hasMode(S_IFCHR)
    }

    var isFIFO: Bool {
        return hasMode(S_IFIFO)
    }

    private func hasMode(_ mode: mode_t) -> Bool {
        return (st_mode & mode) == mode
    }
}
