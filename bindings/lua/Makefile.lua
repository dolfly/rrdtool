
print(string.format('%s %s %s\n', '# Makefile generated by', _VERSION, 'from Makefile.lua.\n'))

local opts = {
  LUA                 = '/usr/bin/lua',
  LUA_MAJOR           = '5',
  LUA_MINOR           = '0',
  LUA_HAVE_COMPAT51   = 'HAVE_COMPAT51',
  LUA_RRD_LANGPREF    = '/scratch/rrd4/lib/lua',
  LUA_CFLAGS          = '-I/usr/include//lua50  ',
  LUA_LFLAGS          = '-llualib50 -llua50  ',
  LUA_SRCS            = 'rrdlua.c',
  LUA_OBJS            = 'rrdlua.o',
  LUA_INSTALL_CMOD    = '/scratch/rrd4/lib/lua/5.0',
  CC                  = 'gcc',
}

-- doesn't preserve key order, but it's OK
for k, v in pairs(opts) do
  print(string.format('%s=%s', k, v))
end

local lua_ver = opts['LUA_MAJOR'] .. '.' .. opts['LUA_MINOR']

print([[

T= rrd
# Version
LIB_VERSION=0.0.9

# OS dependent
LIB_EXT= .so

LIBNAME= $T-$(LIB_VERSION)$(LIB_EXT)

RRD_CFLAGS=-I../../src
RRD_LIB_DIR=-L../../src/.libs -lrrd

# Set shared object options to what your platform requires
# For Solaris - tested with 2.6, gcc 2.95.3 20010315 and Solaris ld:
# LIB_OPTION= -G -dy
# For GNU ld:
LIB_OPTION= -shared -dy

# Choose the PIC option
# safest, works on most systems
PIC=-fPIC
# probably faster, but may not work on your system
#PIC=-fpic

# Compilation directives
OPTIONS= -O3 -Wall $(PIC) -fomit-frame-pointer -pedantic-errors -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings
LIBS= $(RRD_LIB_DIR) $(LUA_LFLAGS) -lm
CFLAGS= $(OPTIONS) $(LUA_CFLAGS) $(RRD_CFLAGS) -DLIB_VERSION=\"$(LIB_VERSION)\" -DLUA$(LUA_MAJOR)$(LUA_MINOR) -D$(LUA_HAVE_COMPAT51)

all: $(LIBNAME)

lib: $(LIBNAME)

*.o:	*.c

$(LIBNAME): $(LUA_OBJS)
	$(CC) $(CFLAGS) $(LIB_OPTION) $(LUA_OBJS) $(LIBS) -o $(LIBNAME)

install: $(LIBNAME)
	mkdir -p $(LUA_INSTALL_CMOD)
	cp $(LIBNAME) $(LUA_INSTALL_CMOD)
	#strip $(LUA_INSTALL_CMOD)/$(LIBNAME)
	(cd $(LUA_INSTALL_CMOD) ; rm -f $T$(LIB_EXT) ; ln -fs $(LIBNAME) $T$(LIB_EXT))]])
if lua_ver == '5.0' and opts['LUA_HAVE_COMPAT51'] ~= 'HAVE_COMPAT51' then
  print([[
	mkdir -p $(LUA_RRD_LANGPREF)/5.0
	cp compat-5.1r5/compat-5.1.lua $(LUA_RRD_LANGPREF)/5.0
]])
end

print([[

test.lua: $(LIBNAME) test.lua.bottom
	@echo "-- Created by Makefile." > test.lua
	@echo "-- Test script adapted from the one in the Ruby binding." > test.lua
	@echo >> test.lua]])
if lua_ver == '5.0' then
  print([[
	@echo "--- compat-5.1.lua is only required for Lua 5.0 ----------" >> test.lua]])

  if opts['LUA_HAVE_COMPAT51'] ~= 'HAVE_COMPAT51' then
    print([[
	@echo "original_LUA_PATH = LUA_PATH" >> test.lua
	@echo "-- try only compat-5.1.lua installed with RRDtool package" >> test.lua
	@echo "LUA_PATH = '$(LUA_RRD_LANGPREF)/5.0/?.lua'" >> test.lua]])
  end
    print([[
	@echo "local r = pcall(require, 'compat-5.1')" >> test.lua
	@echo "if not r then" >> test.lua
	@echo "  print('** compat-5.1.lua not found')" >> test.lua
	@echo "  os.exit(1)" >> test.lua
	@echo "end" >> test.lua]])

  if opts['LUA_HAVE_COMPAT51'] ~= 'HAVE_COMPAT51' then
    print([[
	@echo "LUA_PATH = original_LUA_PATH" >> test.lua
	@echo "original_LUA_PATH = nil" >> test.lua]])
  end
  print([[
	@echo "----------------------------------------------------------" >> test.lua
	@echo >> test.lua]])
end
if opts['LUA_RRD_LANGPREF'] .. '/' .. lua_ver == opts['LUA_INSTALL_CMOD'] then
  print([[
	@echo "package.cpath = '$(LUA_INSTALL_CMOD)/?.so;' .. package.cpath" >> test.lua]])
end
print([[
	@cat test.lua.bottom >> test.lua

test: test.lua
	$(LUA) test.lua

clean:
	rm -f $(LIBNAME) $(LUA_OBJS) test.lua *.so *.rrd *.xml *.png *~
]])

