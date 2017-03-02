# XXX
cmake_minimum_required(VERSION 2.8.7)
project (oops)

include_directories(thirdparty/include thirdparty/boost_1_58_0 . src src/proto)

set(CMAKE_CXX_FLAGS "-std=c++11 -g")
#set(CMAKE_CXX_FLAGS "-std=c++11 -fno-use-linker-plugin")
set(CMAKE_CXX_STANDARD 11)
set(OOPS_LINK_LIBS libsofa-pbrpc.a libgflags.a libglog.a libprotobuf.a libsnappy.a
	tcmalloc unwind pthread)
link_directories(thirdparty/lib/)

# XXX
ADD_SUBDIRECTORY(src/proto src/proto)

file(GLOB common src/common/*.cc)
file(GLOB flag src/flags.cc)
file(GLOB rpc src/rpc/*.cc)
file(GLOB master src/master/*.cc)
file(GLOB cli src/client/*.cc)

include_directories(${ProtobufIncludePath})

add_executable(oopsmaster ${flag} ${common} ${master})
target_link_libraries(oopsmaster proto ${OOPS_LINK_LIBS} pthread z rt)

add_executable(oopscli ${flag} ${rpc} ${common} ${cli})
target_link_libraries(oopscli proto ${OOPS_LINK_LIBS} pthread z rt)
