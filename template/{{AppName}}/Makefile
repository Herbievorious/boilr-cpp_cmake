CMAKE_FLAGS ?=
BUILD_DIR ?= build/

all: release-x86
release: release-x86
debug: debug-x86

release-x86: override CMAKE_FLAGS += -DCMAKE_BUILD_TYPE=Release
release-x86: setup_cmake example

debug-x86: override CMAKE_FLAGS += -DCMAKE_BUILD_TYPE=Debug
debug-x86: setup_cmake example

setup_cmake:
	@mkdir -p build
	@cd $(BUILD_DIR) && CXX=$(CXX) cmake $(CMAKE_FLAGS) ../

example:
	@cd $(BUILD_DIR) && make --no-print-directory

clean:
	@cd $(BUILD_DIR) && make clean
	rm -rf CMakeFiles CMakeCache.txt cmake_install.cmake

distclean:
	rm -rf build
