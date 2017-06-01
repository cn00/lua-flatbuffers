-- premake5.lua
--[[
Usage: 
	windows: premake5.exe --os=windows vs2015
	linux:  premake5.exe --os=linux gmake
]]

local lua_include_dir = "../third_party/lua/include"
local lib_dir = "../third_party/lib"

defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }
defines { "LUAINTF_HEADERS_ONLY=0"}

workspace "lfb"
	configurations { "Debug", "Release" }

project "liblua"
	kind "StaticLib"
	targetdir "../bin/%{cfg.buildcfg}"
	targetprefix ""  -- linux: lfb.so

	--[[
	From: https://github.com/SteveKChiu/lua-intf
	By default LuaIntf expect the Lua library to build under C++.
	If you really want to use Lua library compiled under C,
	you can define LUAINTF_LINK_LUA_COMPILED_IN_CXX to 0:
	--]]
	-- defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }

	files {
		"../third_party/lua/src/**.c",
		"../third_party/lua/src/**.h",
		"../third_party/lua/include/**.h",
	}
	includedirs {
		"../third_party/lua/src",
		"../third_party/lua/include",
		lua_include_dir,
	}
	libdirs {
		-- lib_dir,
	}
	flags {
		"C++11",
	}

	filter "configurations:Debug"
		flags { "Symbols" }
		libdirs { lib_dir .. "/Debug" }
	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		libdirs { lib_dir .. "/Release" }
	filter {}

	links {
		-- "liblua.dll",
		-- "flatbuffers"
	}

project "libfblua"
	kind "SharedLib"
	targetdir "../bin/%{cfg.buildcfg}"
	targetprefix ""  -- linux: lfb.so

	--[[
	From: https://github.com/SteveKChiu/lua-intf
	By default LuaIntf expect the Lua library to build under C++.
	If you really want to use Lua library compiled under C,
	you can define LUAINTF_LINK_LUA_COMPILED_IN_CXX to 0:
	--]]
	-- defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }

	files {
		"../src/**.h",
		"../src/**.cpp",
		"../third_party/lua-intf/**.cpp",
		-- "../third_party/lua/src/*.c",
	}
	includedirs {
		"../src",
		"../third_party/lua-intf",
		"../third_party/lua/src",
		"../third_party/flatbuffers/grpc",
		"../third_party/flatbuffers/include",
		lua_include_dir,
	}
	libdirs {
		lib_dir,
	}
	flags {
		"C++11",
	}

	filter "configurations:Debug"
		flags { "Symbols" }
		libdirs { lib_dir .. "/Debug" }
	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		libdirs { lib_dir .. "/Release" }
	filter {}

	links {
		"liblua",
		"libflatbuffers",
	}

project "libflatbuffers"
	kind "StaticLib"
	targetdir "../bin/%{cfg.buildcfg}"
	targetprefix ""

	--[[
	From: https://github.com/SteveKChiu/lua-intf
	By default LuaIntf expect the Lua library to build under C++.
	If you really want to use Lua library compiled under C,
	you can define LUAINTF_LINK_LUA_COMPILED_IN_CXX to 0:
	--]]
	-- defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }

	files {
		"../third_party/flatbuffers/src/**.cpp",
		"../third_party/flatbuffers/grpc/src/compiler/cpp_generator.cc",
	}
	includedirs {
		"../src",
		"../third_party/lua-intf",
		"../third_party/flatbuffers/grpc",
		"../third_party/flatbuffers/include",
		lua_include_dir,
	}
	libdirs {
		lib_dir,
	}
	flags {
		"C++11",
	}

	filter "configurations:Debug"
		flags { "Symbols" }
		libdirs { lib_dir .. "/Debug" }
	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		libdirs { lib_dir .. "/Release" }
	filter {}

	links {
		-- "flatbuffers"
	}

project "luac"
	kind "ConsoleApp"
	targetdir "../bin/%{cfg.buildcfg}"
	targetprefix ""

	--[[
	From: https://github.com/SteveKChiu/lua-intf
	By default LuaIntf expect the Lua library to build under C++.
	If you really want to use Lua library compiled under C,
	you can define LUAINTF_LINK_LUA_COMPILED_IN_CXX to 0:
	--]]
	-- defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }

	files {
		"../third_party/lua/src/wmain.cc",
	}
	includedirs {
		"../third_party/lua/src",
		"../third_party/lua/include",
		lua_include_dir,
	}
	libdirs {
		lib_dir,
	}
	flags {
		"C++11",
	}

	filter "configurations:Debug"
		flags { "Symbols" }
		libdirs { lib_dir .. "/Debug" }
	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		libdirs { lib_dir .. "/Release" }
	filter {}

	links {
		"liblua",
		-- "libflatbuffers"
	}

project "flatc"
	kind "ConsoleApp"
	targetdir "../bin/%{cfg.buildcfg}"
	targetprefix ""

	--[[
	From: https://github.com/SteveKChiu/lua-intf
	By default LuaIntf expect the Lua library to build under C++.
	If you really want to use Lua library compiled under C,
	you can define LUAINTF_LINK_LUA_COMPILED_IN_CXX to 0:
	--]]
	-- defines { "LUAINTF_LINK_LUA_COMPILED_IN_CXX=0" }

	files {
		"../third_party/flatbuffers/src/flatc.cxx",
	}
	includedirs {
		"../src",
		"../third_party/lua-intf",
		"../third_party/flatbuffers/grpc",
		"../third_party/flatbuffers/include",
		lua_include_dir,
	}
	libdirs {
		lib_dir,
	}
	flags {
		"C++11",
	}

	filter "configurations:Debug"
		flags { "Symbols" }
		libdirs { lib_dir .. "/Debug" }
	filter "configurations:Release"
		defines { "NDEBUG" }
		symbols "On"
		libdirs { lib_dir .. "/Release" }
	filter {}

	links {
		"libflatbuffers"
	}


