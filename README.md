Raspberry Pi 2 and Raspberry Pi 3 use 32-bit ARM CPUs.  The highest MongoDB version that will run on 32 bit is v3.2.  This docker container aims to provide compiled binaries from the v3.2 MongoDB sources.

The Raspbian repositories only provide an older version of MongoDB (2.4.14).

## cross-compile

The container can be built on x86 with normal docker build commands, after prepareing QEMU
```
docker run --rm --privileged multiarch/qemu-user-static:register --reset

docker build -t rpi2-mongodb-compile:3.2.22 .
```

The built container can be run on x86:
```
docker run -it --rm rpi2-mongodb-compile:3.2.22 /usr/bin/qemu-arm-static /bin/bash
```

## Issues

### unnecessary parentheses in boost lib
```
In file included from src/third_party/boost-1.56.0/boost/mpl/aux_/na_assert.hpp:23,
                 from src/third_party/boost-1.56.0/boost/mpl/arg.hpp:25,
                 from src/third_party/boost-1.56.0/boost/mpl/placeholders.hpp:24,
                 from src/third_party/boost-1.56.0/boost/iterator/iterator_categories.hpp:17,
                 from src/third_party/boost-1.56.0/boost/iterator/detail/facade_iterator_category.hpp:7,
                 from src/third_party/boost-1.56.0/boost/iterator/iterator_facade.hpp:14,
                 from src/third_party/boost-1.56.0/boost/filesystem/path.hpp:28,
                 from src/third_party/boost-1.56.0/boost/filesystem/operations.hpp:25,
                 from src/mongo/shell/dbshell.cpp:34:
src/third_party/boost-1.56.0/boost/mpl/assert.hpp:188:21: error: unnecessary parentheses in declaration of 'assert_arg' [-Werror=parentheses]
 failed ************ (Pred::************
                     ^
src/third_party/boost-1.56.0/boost/mpl/assert.hpp:193:21: error: unnecessary parentheses in declaration of 'assert_not_arg' [-Werror=parentheses]
 failed ************ (boost::mpl::not_<Pred>::************
                     ^
cc1plus: all warnings being treated as errors
scons: *** [build/opt/mongo/shell/dbshell.o] Error 1
scons: building terminated because of errors.
```

```
src/third_party/boost-1.56.0/boost/mpl/assert.hpp:190:5: error: expected initializer before ')' token
     );
     ^
src/third_party/boost-1.56.0/boost/mpl/assert.hpp:195:5: error: expected initializer before ')' token
     );
     ^
```


```
RUN sed -i '188s/(Pred::/Pred::/' mongodb-src-r3.2.12/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '190s/)//' mongodb-src-r3.2.12/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '193s/(boost::mpl::not_<Pred>::/boost::mpl::not_<Pred>::/' mongodb-src-r3.2.12/src/third_party/boost-1.56.0/boost/mpl/assert.hpp \
 && sed -i '195s/)//' mongodb-src-r3.2.12/src/third_party/boost-1.56.0/boost/mpl/assert.hpp
```

### error: nonnull argument 'this' compared to NULL [-Werror=nonnull-compare]

```
/usr/bin/python2 src/mongo/db/auth/generate_action_types.py src/mongo/db/auth/action_types.txt build/opt/mongo/db/auth/action_type.h build/opt/mongo/db/auth/action_type.cpp
g++ -o build/opt/mongo/client/dbclient.o -c -Wnon-virtual-dtor -Woverloaded-virtual -Wno-maybe-uninitialized -std=c++11 -fno-omit-frame-pointer -fPIC -fno-strict-aliasing -ggdb -pthread -Wall -Wsign-compare -Wno-unknown-pragmas -Winvalid-pch -Werror -O2 -Wno-unused-local-typedefs -Wno-unused-function -Wno-deprecated-declarations -Wno-unused-const-variable -Wno-unused-but-set-variable -Wno-missing-braces -fno-builtin-memcmp -DPCRE_STATIC -DNDEBUG -D_FILE_OFFSET_BITS=64 -DBOOST_THREAD_VERSION=4 -DBOOST_THREAD_DONT_PROVIDE_VARIADIC_THREAD -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_THREAD_DONT_PROVIDE_INTERRUPTIONS -DBOOST_THREAD_HAS_NO_EINTR_BUG -Isrc/third_party/asio-asio-1-11-0/asio/include -Isrc/third_party/s2 -Isrc/third_party/pcre-8.39 -Isrc/third_party/boost-1.56.0 -Ibuild/opt -Isrc src/mongo/client/dbclient.cpp
In file included from src/mongo/platform/compiler.h:132,
                 from src/mongo/util/invariant.h:30,
                 from src/mongo/base/string_data.h:39,
                 from build/opt/mongo/base/error_codes.h:31,
                 from src/mongo/base/status.h:34,
                 from src/mongo/client/dbclient.cpp:36:
src/mongo/client/dbclientcursor.h: In member function 'void mongo::DBClientCursor::_assertIfNull() const':
src/mongo/util/assert_util.h:233:28: error: nonnull argument 'this' compared to NULL [-Werror=nonnull-compare]
         if (MONGO_unlikely(!(expr))) {      \
                            ^~~~~~~
src/mongo/platform/compiler_gcc.h:66:80: note: in definition of macro 'MONGO_unlikely'
 #define MONGO_unlikely(x) static_cast<bool>(__builtin_expect(static_cast<bool>(x), 0))
                                                                                ^
src/mongo/util/assert_util.h:319:17: note: in expansion of macro 'MONGO_uassert'
 #define uassert MONGO_uassert
                 ^~~~~~~~~~~~~
src/mongo/client/dbclientcursor.h:295:9: note: in expansion of macro 'uassert'
         uassert(13348, "connection died", this);
         ^~~~~~~
cc1plus: all warnings being treated as errors
scons: *** [build/opt/mongo/client/dbclient.o] Error 1
scons: building terminated because of errors.
The command '/bin/sh -c cd mongodb-src-r3.2.12  && scons mongo mongod --wiredtiger=off --mmapv1=on' returned a non-zero code: 2
```


```
RUN cd mongodb-src-r3.2.12 \
 && scons mongo --wiredtiger=off --mmapv1=on --disable-warnings-as-errors
```

### Newer versions of glibc stopped including sys/sysmacros.h automatically with sys/type.h

```
g++ -o build/opt/mongo/db/storage/mmap_v1/mmap_v1_engine.o -c -Wnon-virtual-dtor -Woverloaded-virtual -Wno-maybe-uninitialized -std=c++11 -fno-omit-frame-pointer -fPIC -fno-strict-aliasing -ggdb -pthread -Wall -Wsign-compare -Wno-unknown-pragmas -Winvalid-pch -O2 -Wno-unused-local-typedefs -Wno-unused-function -Wno-deprecated-declarations -Wno-unused-const-variable -Wno-unused-but-set-variable -Wno-missing-braces -fno-builtin-memcmp -DPCRE_STATIC -DNDEBUG -D_FILE_OFFSET_BITS=64 -DBOOST_THREAD_VERSION=4 -DBOOST_THREAD_DONT_PROVIDE_VARIADIC_THREAD -DBOOST_SYSTEM_NO_DEPRECATED -DBOOST_THREAD_DONT_PROVIDE_INTERRUPTIONS -DBOOST_THREAD_HAS_NO_EINTR_BUG -Isrc/third_party/asio-asio-1-11-0/asio/include -Isrc/third_party/s2 -Isrc/third_party/pcre-8.39 -Isrc/third_party/boost-1.56.0 -Ibuild/opt -Isrc src/mongo/db/storage/mmap_v1/mmap_v1_engine.cpp
src/mongo/db/storage/mmap_v1/mmap_v1_engine.cpp: In function 'void mongo::{anonymous}::checkReadAhead(const string&)':
src/mongo/db/storage/mmap_v1/mmap_v1_engine.cpp:170:61: error: 'major' was not declared in this scope
         string path = str::stream() << "/sys/dev/block/" << major(dev) << ':' << minor(dev)
                                                             ^~~~~
src/mongo/db/storage/mmap_v1/mmap_v1_engine.cpp:170:82: error: 'minor' was not declared in this scope
         string path = str::stream() << "/sys/dev/block/" << major(dev) << ':' << minor(dev)
                                                                                  ^~~~~
src/mongo/db/storage/mmap_v1/mmap_v1_engine.cpp:170:82: note: suggested alternative: 'mknod'
         string path = str::stream() << "/sys/dev/block/" << major(dev) << ':' << minor(dev)
                                                                                  ^~~~~
                                                                                  mknod
scons: *** [build/opt/mongo/db/storage/mmap_v1/mmap_v1_engine.o] Error 1
scons: building terminated because of errors.
The command '/bin/sh -c cd mongodb-src-r3.2.12  && scons mongo mongod --wiredtiger=off --mmapv1=on --disable-warnings-as-errors' returned a non-zero code: 2
```

```
RUN sed -i '35i#include <sys/sysmacros.h>' mongodb-src-r3.2.12/src/mongo/db/storage/paths.h
```

### MongoDB with `-O2` causes segfault on ARM

Any time Mongo is compiled with GCC Optimization, the compiled binary will segfault.
```
root@43262540c0f6:/# mongod
2020-05-16T12:16:42.564+0000 F -        [main] Invalid access at address: 0
2020-05-16T12:16:42.644+0000 F -        [main] Got signal: 11 (Segmentation fault).
```

Changing from `-O2` to `-O1` didn't help:
```
 && sed -i '1494s/O2/O1/' mongodb-src/SConstruct \
```

The only thing that I got to work was disabling optimization in the scons script:
```
 && scons mongod mongo mongos --opt=off --wiredtiger=off --mmapv1=on --disable-warnings-as-errors \
```

## References
* https://pimylifeup.com/mongodb-raspberry-pi/
* https://www.balena.io/docs/reference/base-images/base-images-ref/
* https://koenaerts.ca/compile-and-install-mongodb-on-raspberry-pi/
* https://github.com/CauldronDevelopmentLLC/cbang/commit/420c236389726635b669c4e40b2dd80f598a037e
* https://bugzilla.mozilla.org/show_bug.cgi?id=1329798
* https://github.com/ckulka/docker-multi-arch-example
* https://hub.docker.com/r/ckulka/multi-arch-example
* https://bodhi.fedoraproject.org/updates/FEDORA-2016-ad367c57b0

