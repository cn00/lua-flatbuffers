package.cpath = package.cpath .. ";../bin/Debug/?.dll"

lfb = require("libfblua")
inspect = require("inspect")

assert(lfb.load_bfbs_file("../third_party/flatbuffers/tests/monster_test.bfbs"))

monster = {
	pos = {x=1,y=2.2,z=3.3,test1=111.222,test2="Red",test3={a=1,b=2}},
	name = "my_monster",
	inventory = {1,2,3},
	testarrayoftables = {{name="M1"}, {name="M2"}},
	testarrayofstring = {"s1", "s2", "s3"},
	testarrayofstring2 = {"22"},
	testarrayofbools = {true, false, 1, 0, 2, 0},
	enemy = {name="enemy"},
	test_type = "TestSimpleTableWithEnum",
	test = {color = "Red"},
	test4 = {{a=1,b=2},{a=3,b=4}},
	testnestedflatbuffer = {1,2},
	testempty = {},
	testbool = true,
	testhashu64_fnv1a = 123456789,
}

function test_monster()
	buf = assert(lfb.encode("Monster", monster))
	t = assert(lfb.decode("Monster", buf))
	assert("my_monster" == t.name)
	assert(t.testhashu64_fnv1a == 123456789)
	assert("enemy" == t.enemy.name)
end  -- test_monster()

function test_no_type()
	buf, err = lfb.encode("Abcd", {})
	assert(err == "no type Abcd")
end

function test_required()
	buf = assert(lfb.encode("TestSimpleTableWithEnum", {}))
	t = assert(lfb.decode("TestSimpleTableWithEnum", buf))
	assert(t.color == 2)
	
	buf, err = lfb.encode("Monster", {})
	assert(err == "missing required field Monster.name")
	-- If disable required fields check in encoding:
	-- t, err = lfb.decode("Monster", buf)
	-- assert(err == "missing required field Monster.name")

	buf = assert(lfb.encode("Monster", {name="abc"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.name == "abc")
end  -- test_required()

function test_too_short()
	TO_SHORT = "buffer is too short"
	t, err = lfb.decode("Monster", "")
	assert(err == TO_SHORT)
	t, err = lfb.decode("Monster", "123")
	assert(err == TO_SHORT)
	assert(not lfb.decode("Monster", "1234"))
	assert(not lfb.decode("Monster", "1234"))
end

function test_not_table()
	buf, err = lfb.encode("Monster", nil)
	assert(nil == buf)
	assert(err == "lua data is not table but nil")
	buf, err = lfb.encode("Monster", 1234)
	assert(err == "lua data is not table but number")
	buf, err = lfb.encode("Monster", print)
	assert(err == "lua data is not table but function")
end  -- test_not_table()

function test_type_convert()
	buf = assert(lfb.encode("Monster", {name=123}))
	t = assert(lfb.decode("Monster", buf))
	assert("123" == t.name)
	buf = assert(lfb.encode("Test", {a=1, b=256}))  -- Test.b is byte
	t = assert(lfb.decode("Test", buf))
	assert(1 == t.a and 0 == t.b)
	buf, err = lfb.encode("Test", {a=1.2, b=2})
	assert(err == "can not convert field Test.a(1.2) to integer")
	buf = assert(lfb.encode("Test", {a=1, b="25"}))
	t = assert(lfb.decode("Test", buf))
	assert(1 == t.a and 25 == t.b)
	buf = assert(lfb.encode("Monster", {name="", testf="1.2"}))
	t = assert(lfb.decode("Monster", buf))
	assert(math.type(t.testf) == "float")
	assert(tostring(t.testf) == "1.2000000476837")
end  -- test_type_convert()

function test_string_field()
	assert(lfb.encode("Monster", {name=""}))
	buf, err = lfb.encode("Monster", {name=print})
	assert(err == "string field Monster.name is function")
end  -- test_string_field()

function test_encode_struct()
	buf, err = lfb.encode("Test", {})
	assert(err == "missing struct field Test.a")
	buf, err = lfb.encode("Test", {a=1})
	assert(err == "missing struct field Test.b")
	buf, err = lfb.encode("Test", {a=1, b=2, c=3})
	assert(err == "illegal field Test.c")
	buf = assert(lfb.encode("Test", {a=1, b=2}))
	t = assert(lfb.decode("Test", buf))
	assert(t.a == 1 and t.b == 2)
	buf, err = lfb.encode("Test", {a=1, b={}})
	assert(err == "can not convert field Test.b(table) to integer")
end  -- test_encode_struct()

function test_encode_nested_struct()
	org = {x=1,y=2,z=3.3,test1=0.001,test2=0,test3={a=1,b=2}}
	buf = assert(lfb.encode("Vec3", org))
	t = assert(lfb.decode("Vec3", buf))
	assert(1 == t.test3.a)
	assert(2 == t.test3.b)
	assert(0 == t.test2)
end  -- test_encode_nested_struct()

function test_to_num()
	assert(lfb.test_to_num(0)["int8"] == 0)
	assert(lfb.test_to_num("123")["int8"] == 123)
	assert(lfb.test_to_num(9223372036854775807)["int64"] == 9223372036854775807)
	assert(lfb.test_to_num("9223372036854775807")["int64"] == 9223372036854775807)
	t = lfb.test_to_num(0.1)
	assert(t["double"] == 0.1)
	assert(tostring(t["float"]) == "0.10000000149012")
	assert(t["int8"] == "can not convert field test(0.1) to integer")
	assert(lfb.test_to_num(256)["uint8"] == 0)
	assert(lfb.test_to_num(nil)["uint8"] == "can not convert field test(nil) to integer")
	t = lfb.test_to_num(true)
	assert(t.int8 == 1)
	t = lfb.test_to_num(false)
	assert(t.uint8 == 0)
end  -- test_to_num()

function test_enum()
	local name = "TestSimpleTableWithEnum"
	buf = assert(lfb.encode(name, {}))
	t = assert(lfb.decode(name, buf))
	assert(2 == t.color)
	buf = assert(lfb.encode(name, {color = 123}))
	t = assert(lfb.decode(name, buf))
	assert(123 == t.color)
	buf = assert(lfb.encode(name, {color = "Green"}))
	t = assert(lfb.decode(name, buf))
	assert(2 == t.color)
	buf = assert(lfb.encode(name, {color = "Blue"}))
	t = assert(lfb.decode(name, buf))
	assert(8 == t.color)
	
	buf = assert(lfb.encode("Vec3", {x=1,y=2,z=3,
		test1=1, test2="Red", test3={a=1,b=2}}))
	t = assert(lfb.decode("Vec3", buf))
	assert(1 == t.test2)
end  -- test_enum()

function test_encode_illegal_field()
	buf, err = lfb.encode("Monster", {name="", abcd=1})
	assert(err == "illegal field Monster.abcd")
end  -- test_encode_illegal_field()

function test_mygame_example2_monster()
	buf = assert(lfb.encode("MyGame.Example2.Monster", {}))
	-- no type MyGame.Example2.Monster
end  -- test_mygame_example2_monster()

function test_encode_depricated_field()
	buf, err = lfb.encode("Monster", {name="", friendly=true})
	assert(err == "deprecated field Monster.friendly")
end  -- test_encode_depricated_field()

function test_bool_field()
	buf = assert(lfb.encode("Monster", {name="", testbool=true}))
	t = assert(lfb.decode("Monster", buf))
	assert(true == t.testbool)
	buf = assert(lfb.encode("Monster", {name="", testbool=false}))
	t = assert(lfb.decode("Monster", buf))
	assert(false == t.testbool)
	buf = assert(lfb.encode("Monster", {name="", testbool=123}))
	t = assert(lfb.decode("Monster", buf))
	assert(true == t.testbool)
end  -- test_bool_field()

function test_byte_vector()
	buf, err = lfb.encode("Monster", {name="", inventory=1234})
	assert(err == "array field Monster.inventory is not array but number")
	buf, err = lfb.encode("Monster", {name="", inventory={1.1}})
	assert(err == "can not convert field Monster.inventory[1](1.1) to integer")
	buf = assert(lfb.encode("Monster", {name="", inventory={1,2}}))
	t = assert(lfb.decode("Monster", buf))
	assert(1 == t.inventory[1] and 2 == t.inventory[2])
	buf = assert(lfb.encode("Monster", {name="", inventory={
		1,2, [-1]=-1, [100]=100, x=101}}))
	t = assert(lfb.decode("Monster", buf))
	assert(2 == #t.inventory)
	assert(nil == t.inventory[-1] and
		nil == t.inventory[100] and
		nil == t.inventory.x)
end  -- test_byte_vector()

function test_bool_vector()
	buf = assert(lfb.encode("Monster", {name="", testarrayofbools={[1]=true}}))
	t = assert(lfb.decode("Monster", buf))
	assert(true == t.testarrayofbools[1])
	buf = assert(lfb.encode("Monster", {name="", testarrayofbools={1,0,1,0}}))
	t = assert(lfb.decode("Monster", buf))
	local a = t.testarrayofbools
	assert(true == a[1] and false == a[2] and a[3] and not a[4])
end  -- test_bool_vector()

function test_string_vector()
	buf = assert(lfb.encode("Monster", {name="", testarrayofstring={"abcd", 1234}}))
	t = assert(lfb.decode("Monster", buf))
	assert("abcd" == t.testarrayofstring[1])
	assert("1234" == t.testarrayofstring[2])
	buf, err = lfb.encode("Monster", {name="", testarrayofstring={print}})
	assert(err == "string vector item Monster.testarrayofstring[1] is function")
end  -- test_string_vector()

function test_struct_vector()
	buf = assert(lfb.encode("Monster", {name="", test4={{a=1,b=2}, {a=3,b=4}}}))
	t = assert(lfb.decode("Monster", buf))
	assert(1 == t.test4[1].a)
	assert(2 == t.test4[1].b)
	assert(3 == t.test4[2].a)
	assert(4 == t.test4[2].b)
	buf, err = lfb.encode("Monster", {name="", test4={{a=1}}})
	assert(err == "missing struct field Monster.test4[1].b")
end  -- test_struct_vector()

function test_table_vector()
	buf = assert(lfb.encode("Monster", {name="abcde", testarrayoftables={{name="xyz"}}}))
	t = assert(lfb.decode("Monster", buf))
	a = t.testarrayoftables
	assert("xyz" == a[1].name)

	buf = assert(lfb.encode("Monster", {name="",
		testarrayoftables={{name="a"}, {name="b"}}}))
	t = assert(lfb.decode("Monster", buf))
	a = t.testarrayoftables
	assert("a" == a[1].name)
	assert("b" == a[2].name)
end  -- test_table_vector()

function test_vector_field()
	test_byte_vector()
	test_bool_vector()
	test_string_vector()
	test_struct_vector()
	test_table_vector()
end  -- test_vector_field()

function test_table_field()
	buf = assert(lfb.encode("Monster", {name="",
		testempty={id="test", val=9223372036854775807}}))
	t = assert(lfb.decode("Monster", buf))
	assert("test" == t.testempty.id)
	assert(9223372036854775807 == t.testempty.val)
	assert(0 == t.testempty.count)

	buf, err = lfb.encode("Monster", {name="", testempty=print})
	assert(err == "object Monster.testempty is not a table but function")
end  -- test_table_field()

function test_union_field()
	buf, err = lfb.encode("Monster", {name="", test={}})
	assert(err == "missing union type field Monster.test_type")
	buf, err = lfb.encode("Monster", {name="", test={}, test_type=1234})
	assert(err == "illegal union type Monster.test_type(1234)")
	buf, err = lfb.encode("Monster", {name="", test={}, test_type="Abcd"})
	assert(err == "illegal union type name Monster.test_type(Abcd)")
	buf, err = lfb.encode("Monster", {name="", test={}, test_type=print})
	assert(err == "union type Monster.test_type is function")

	buf = assert(lfb.encode("Monster", {name="", test={name="aaa"}, test_type="Monster"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.test_type == 1)
	assert(t.test.name == "aaa")
	-- Union type starts from 1?
	buf = assert(lfb.encode("Monster", {name="", test={name="aaa"}, test_type=1}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.test_type == 1)

	buf = assert(lfb.encode("Monster", {name="",
		test={}, test_type="TestSimpleTableWithEnum"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.test_type == 2)
	assert(t.test.color == 2)  -- Green
	buf = assert(lfb.encode("Monster", {name="",
		test={color="Red"}, test_type="TestSimpleTableWithEnum"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.test_type == 2)
	assert(t.test.color == 1)  -- Red

	buf, err = lfb.encode("Monster", {name="",
		test={}, test_type="MyGame.Example2.Monster"})
	assert(err == "illegal union type name Monster.test_type(MyGame.Example2.Monster)")
	buf = assert(lfb.encode("Monster", {name="",
		test={}, test_type="MyGame_Example2_Monster"}))
	t = assert(lfb.decode("Monster", buf))
	assert(t.test_type == 3)
	assert(t.test.name == nil)
end  -- test_union_field()

function test_struct_field()
	buf = assert(lfb.encode("Monster", {name="abcde", pos={
		x=1.23,y=1.23,z=1.233,test1=1.23,test2=1,test3={a=1234,b=123}}}))
	t = assert(lfb.decode("Monster", buf))
	assert(1234 == t.pos.test3.a)
end  -- test_struct_field()

function str_to_bytes(s)
	return {string.byte(s, 1, -1)}
end  -- str_to_bytes()

function bytes_to_str(arr)
	return string.char(table.unpack(arr))
end  -- bytes_to_str()

-- Return a modified buffer copy. Set [idx] to new_value(0..255).
function mod(buf, idx, new_value)
	assert("string" == type(buf))
	assert("integer" == math.type(idx))
	assert(idx > 0 and idx <= #buf)
	new_value = new_value or 255
	local b = str_to_bytes(buf)
	b[idx] = new_value
	return bytes_to_str(b)
end  -- mod()

function verify_random(name, tbl, count)
	assert("string" == type(name))
	assert("table" == type(tbl))
	assert("number" == type(count))
	buf = assert(lfb.encode(name, tbl))
	assert(lfb.decode(name, buf))
	local result = {}
	for i = 1, count do
		local idx = math.random(1, #buf)
		local b = str_to_bytes(buf)
		local v = math.random(0, 255) 
		b[idx] = v
		t, err = lfb.decode(name, bytes_to_str(b))
		result[err] = string.format("[%d]->%d", idx, v)
	end
	return result
end  -- verify_random

function verify(name, tbl)
	assert("string" == type(name))
	assert("table" == type(tbl))
	local result = ""
	buf = assert(lfb.encode(name, tbl))
	assert(lfb.decode(name, buf))
	for i = 1, #buf do
		local b = str_to_bytes(buf);
		b[i] = 255
		t, err = lfb.decode(name, bytes_to_str(b))
		result = result .. string.format("[%d] %s\n", i, err)
	end  -- for
	return result
end  -- verify()

function test_decode_verify()
	verify("Monster", monster);
	verify_random("Monster", monster, 1000);
end  -- test_decode_verify()

function test_all()
	test_monster()
	print("test_monster passed.")

	test_no_type()
	print("test_no_type passed.")
	test_required()
	print("test_required passed.")
	
	test_too_short()
	print("test_too_short passed.")
	test_not_table()
	print("test_not_table passed.")
	test_type_convert()
	print("test_type_convert passed.")
	test_string_field()
	print("test_string_field passed.")
	test_encode_struct()
	print("test_encode_struct passed.")
	test_encode_nested_struct()
	print("test_encode_nested_struct passed.")
	test_to_num()
	print("test_to_num passed.")
	test_enum()
	print("test_enum passed.")
	test_encode_illegal_field()
	print("test_encode_illegal_field passed.")
	-- Todo: test_mygame_example2_monster()
	test_encode_depricated_field()
	print("test_encode_depricated_field passed.")
	test_bool_field()
	print("test_bool_field passed.")
	test_vector_field()
	print("test_vector_field passed.")
	test_table_field()
	print("test_table_field passed.")
	test_union_field()
	print("test_union_field passed.")
	test_struct_field()
	print("test_struct_field passed.")

	-- test_decode_verify() is slow. Run manually.
	print("All test passed.")
end  -- test_all()

test_all()

return 0
