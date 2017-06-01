// FlatBuffers library for Lua.
// Author: Jin Qing ( http://blog.csdn.net/jq0123 )

#include "schema_cache.h"  // for SchemaCache

#include "decoder/root_decoder.h"  // for RootDecoder
#include "encoder/encoder.h"  // for Encoder
#include "encoder/encoder_context.h"  //  for EncoderContext

#include <LuaIntf/LuaIntf.h>

#include <iostream>

using LuaIntf::LuaRef;

namespace {

void test()
{
	std::cout << "test...\n";
}

LuaRef TestToNum(const LuaRef& luaVal)
{
	return Encoder::TestToNum(luaVal);
}

std::tuple<LuaRef, std::string> TestToStr(const LuaRef& luaVal)
{
	try{
		std::string s(luaVal.toValue<const char*>());
		return std::make_tuple(LuaRef::fromValue(
			luaVal.state(), "Hello, " + s), "OK");
	}
	catch(...)
	{
	}
	return std::make_tuple(LuaRef(luaVal.state(), nullptr), "Exception");
}

SchemaCache& GetCache()
{
	static SchemaCache s_cache;
	return s_cache;
}

std::tuple<bool, std::string> LoadBfbsFile(const std::string& sBfbsFile)
{
	return GetCache().LoadBfbsFile(sBfbsFile);
}

std::tuple<bool, std::string> LoadBfbs(const std::string& sBfbs)
{
	return GetCache().LoadBfbs(sBfbs);
}

std::tuple<bool, std::string> LoadFbsFile(const std::string& sFbsFile)
{
	return GetCache().LoadFbsFile(sFbsFile);
}

std::tuple<bool, std::string> LoadFbs(const std::string& sFbs)
{
	return GetCache().LoadFbs(sFbs);
}

// Encode lua table to buffer.
// Returns (buffer, "") or (nil, error)
std::tuple<LuaRef, std::string> Encode(
	const std::string& sName, const LuaRef& table)
{
	lua_State* L = table.state();
	const reflection::Schema* pSchema = GetCache().GetSchemaOfObject(sName);
	if (!pSchema)
		return std::make_tuple(LuaRef(L, nullptr), "no type " + sName);

	EncoderContext ctx{*pSchema};
	Encoder encoder(ctx);
	if (encoder.Encode(sName, table))
	{
		return std::make_tuple(LuaRef::fromValue(
			L, encoder.GetResultStr()), "");
	}
	return std::make_tuple(LuaRef(L, nullptr), ctx.sError);
}

// Decode buffer to lua table.
// Returns (table, "") or (nil, error)
std::tuple<LuaRef, std::string> Decode(
	lua_State* L,
	const std::string& sName,
	const std::string& buf)
{
	assert(L);
	const reflection::Schema* pSchema = GetCache().GetSchemaOfObject(sName);
	if (!pSchema)
		return std::make_tuple(LuaRef(L, nullptr), "no type " + sName);

	const char* pBuf = buf.data();
	DecoderContext ctx{
		L,
		*pSchema,
		flatbuffers::Verifier(reinterpret_cast<
			const uint8_t *>(buf.data()), buf.size())
	};
	return std::make_tuple(RootDecoder(ctx).Decode(sName, pBuf), ctx.sError);
}

}  // namespace

extern "C"
#if defined(_MSC_VER) || defined(__BORLANDC__) || defined(__CODEGEARC__)
__declspec(dllexport)
#endif
int luaopen_libfblua(lua_State* L)
{
	using namespace LuaIntf;
	LuaRef mod = LuaRef::createTable(L);
	LuaBinding(mod)
		.addFunction("test", &test)
		.addFunction("test_to_num", &TestToNum)
		.addFunction("test_to_str", &TestToStr)
		.addFunction("load_bfbs_file", &LoadBfbsFile)
		.addFunction("load_bfbs", &LoadBfbs)
		.addFunction("load_fbs_file", &LoadFbsFile)
		.addFunction("load_fbs", &LoadFbs)
		.addFunction("encode", &Encode)
		.addFunction("decode", [L](const std::string& sName,
			const std::string& buf) {
			return Decode(L, sName, buf);
		});
	mod.pushToStack();
	return 1;
}
