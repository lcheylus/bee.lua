local lm = require "luamake"
lm.rootdir = ".."

require 'config'
lm:import 'common.lua'

local BOOTSTRAP = lm.EXE_NAME or "bootstrap"

lm:executable (BOOTSTRAP) {
    deps = { "source_bee", "source_lua" },
    includes = "3rd/lua",
    sources = "bootstrap/*.cpp",
    windows = {
        sources = {
            "3rd/lua/utf8_crt.c",
            lm.EXE_RESOURCE,
        }
    },
    msvc = {
        ldflags = {
            "/IMPLIB:$obj/$name/$name.lib"
        }
    },
    macos = {
        defines = "LUA_USE_MACOSX",
        links = { "m", "dl" },
    },
    linux = {
        crt = "static",
        defines = "LUA_USE_LINUX",
        ldflags = "-Wl,-E",
        links = {
            "m", "dl",
            -- https://gcc.gnu.org/bugzilla/show_bug.cgi?id=67791
            "pthread",
        }
    },
    android = {
        defines = "LUA_USE_LINUX",
        ldflags = "-Wl,-E",
        links = { "m", "dl" }
    }
}

local exe = lm.os == 'windows' and ".exe" or ""

lm:copy "copy_script" {
    input = "bootstrap/main.lua",
    output = "$bin/main.lua",
    deps = BOOTSTRAP,
}

lm:build "test" {
    "$bin/"..BOOTSTRAP..exe, "@test/test.lua",
    deps = { BOOTSTRAP, "copy_script" },
    pool = "console",
}

if lm.os == "windows" then
    lm:build "forward_lua" {
        "$luamake", "lua",
        "@bootstrap/forward_lua.lua",
        "@3rd/lua/", "$out",
        BOOTSTRAP..".exe", lm.compiler,
        input = {
            "bootstrap/forward_lua.lua",
            "3rd/lua/lua.h",
            "3rd/lua/lauxlib.h",
            "3rd/lua/lualib.h",
        },
        output = "bootstrap/forward_lua.h",
        deps = {
            lm.LUAMAKE,
        }
    }
    lm:phony {
        input = "bootstrap/forward_lua.h",
        output = "bootstrap/forward_lua.c",
    }
    lm:shared_library "lua54" {
        includes = "bootstrap",
        sources = "bootstrap/forward_lua.c",
        ldflags = "$obj/"..BOOTSTRAP.."/"..BOOTSTRAP..".lib",
        deps = {
            "forward_lua",
            BOOTSTRAP,
        }
    }
end
