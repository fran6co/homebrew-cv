require 'formula'

class CudaRequirement < Requirement
  build true
  fatal true

  satisfy { which 'nvcc' }

  env do
    # Nvidia CUDA installs (externally) into this dir (hard-coded):
    ENV.append 'CFLAGS', "-F/Library/Frameworks"
    # # because nvcc has to be used
    ENV.append 'PATH', which('nvcc').dirname, ':'
  end

  def message
    <<-EOS.undent
      To use this formula with NVIDIA graphics cards you will need to
      download and install the CUDA drivers and tools from nvidia.com.

          https://developer.nvidia.com/cuda-downloads

      Select "Mac OS" as the Operating System and then select the
      'Developer Drivers for MacOS' package.
      You will also need to download and install the 'CUDA Toolkit' package.

      The `nvcc` has to be in your PATH then (which is normally the case).

  EOS
  end
end

class Pcl < Formula
  homepage 'http://www.pointclouds.org/'

  head 'https://github.com/PointCloudLibrary/pcl.git'

  option 'with-examples', 'Build pcl examples.'
  option 'with-tests', 'Build pcl tests.'
  option 'without-tools', 'Build without tools.'
  option 'without-apps', 'Build without apps.'
  option 'without-qvtk', 'Build without qvtk support.'
  option 'with-docs', 'Build with docs.'

  depends_on 'cmake' => :build
  depends_on 'pkg-config' => :build

  if build.with? 'docs'
    depends_on 'doxygen' => :build
  end

  depends_on 'boost'
  depends_on 'eigen'
  depends_on 'flann'
  depends_on 'cminpack'

  depends_on CudaRequirement => :optional

  # PCL doesn't support qhull 2012 yet
  depends_on 'qhull2011'
  depends_on 'libusb'
  depends_on 'glew'
  depends_on 'qt' => :recommended
  if build.with? 'qvtk'
    depends_on 'vtk' => [:recommended,'with-qt']
  else
    depends_on 'vtk' => :recommended
  end
  depends_on 'homebrew/science/openni' => :optional
  depends_on 'homebrew/science/openni2' => :optional

  resource 'sphinx' do
    url 'https://pypi.python.org/packages/source/S/Sphinx/Sphinx-1.2.2.tar.gz'
    sha1 '9e424b03fe1f68e0326f3905738adcf27782f677'
  end

  def patches
    # wrong opengl headers
    if !build.head?
    	fix_gl_headers =  [
	        "apps/in_hand_scanner/src/opengl_viewer.cpp",
	        "surface/include/pcl/surface/3rdparty/opennurbs/opennurbs_gl.h",
        ]

    	fix_glu_headers =  fix_gl_headers + [
	        "apps/point_cloud_editor/src/cloudEditorWidget.cpp",
        ]
        
        inreplace fix_glu_headers, '<GL/glu.h>', '<OpenGL/glu.h>'
        inreplace fix_gl_headers, '<GL/gl.h>', '<OpenGL/gl.h>'
    end
    fixes = []
    
    # fixes GLEW linking and qhull2011
    [DATA] + fixes
  end

  def install
    if not build.head? and build.with? 'openni2'
          raise 'PCL currently requires --HEAD to build openni2 support' 
    end

    raise 'PCL currently requires --HEAD on Mavericks' if MacOS.version == :mavericks and not build.head?

    qhull2011_base = Formula.factory('qhull2011').installed_prefix

    args = std_cmake_args + %W[
      -DGLEW_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/GL
      -DQHULL_ROOT=#{qhull2011_base}
      -DBUILD_SHARED_LIBS:BOOL=ON
      -DBUILD_simulation:BOOL=AUTO_OFF
      -DBUILD_outofcore:BOOL=AUTO_OFF
      -DBUILD_people:BOOL=AUTO_OFF
    ]

    if build.head? and build.with? 'openni2'
      ENV.append 'OPENNI2_INCLUDE', "#{HOMEBREW_PREFIX}/include/ni2"
      ENV.append 'OPENNI2_REDIST', "#{HOMEBREW_PREFIX}/lib/ni2"
      args << "-DBUILD_OPENNI2:BOOL=ON"
    end

    if build.with? "cuda"
      args << "-DWITH_CUDA:BOOL=AUTO_OFF"
    else
      args << "-DWITH_CUDA:BOOL=OFF"
    end

    if build.with? "docs"
      (buildpath/"sphinx").mkpath

      resource("sphinx").stage do
        system "python", "setup.py", "install",
                                     "--prefix=#{buildpath}/sphinx",
                                     "--record=installed.txt",
                                     "--single-version-externally-managed"
      end

      args << "-DPC_SPHINX_EXECUTABLE="+(buildpath/"sphinx/bin")
      args << "-DWITH_DOCS:BOOL=ON"
      args << "-DWITH_TUTORIALS:BOOL=ON"
    else
      args << "-DWITH_TUTORIALS:BOOL=OFF"
      args << "-DWITH_DOCS:BOOL=OFF"
    end

    if build.with? 'apps'
      args = args + %W[
        -DBUILD_apps=AUTO_OFF
        -DBUILD_apps_3d_rec_framework=AUTO_OFF
        -DBUILD_apps_cloud_composer=AUTO_OFF
        -DBUILD_apps_in_hand_scanner=AUTO_OFF
        -DBUILD_apps_modeler=AUTO_OFF
        -DBUILD_apps_optronic_viewer=AUTO_OFF
        -DBUILD_apps_point_cloud_editor=AUTO_OFF
      ]
    else
      args << "-DBUILD_apps:BOOL=OFF"
    end

    if build.without? 'tools'
      args << "-DBUILD_tools:BOOL=OFF"
    end

    if build.with? 'examples'
      args << "-DBUILD_examples:BOOL=ON"
    else
      args << "-DBUILD_examples:BOOL=OFF"
    end

    if build.with? 'tests'
      args << "-DBUILD_global_tests:BOOL=ON"
    else
      args << "-DBUILD_global_tests:BOOL=OFF"
    end

    if build.with? 'openni'
      args << "-DOPENNI_INCLUDE_DIR=#{HOMEBREW_PREFIX}/include/ni"
    else
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_OpenNI:BOOL=TRUE"
    end

    if build.without? 'qt'
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_Qt4:BOOL=TRUE"
    end

    if build.without? 'vtk'
      args << "-DCMAKE_DISABLE_FIND_PACKAGE_VTK:BOOL=TRUE"
    end

    args << '..'
    mkdir 'macbuild' do
      system 'cmake', *args
      system "make"
      system "make install"
      if build.with? 'test'
        system 'make test'
      end
    end
  end
end
__END__
diff --git a/cmake/Modules/FindQhull.cmake b/cmake/Modules/FindQhull.cmake
index f5fd269..2d16436 100644
--- a/cmake/Modules/FindQhull.cmake
+++ b/cmake/Modules/FindQhull.cmake
@@ -47,12 +47,14 @@ find_library(QHULL_LIBRARY
              NAMES ${QHULL_RELEASE_NAME}
              HINTS "${QHULL_ROOT}" "$ENV{QHULL_ROOT}"
              PATHS "$ENV{PROGRAMFILES}/QHull" "$ENV{PROGRAMW6432}/QHull" 
+             NO_DEFAULT_PATH
              PATH_SUFFIXES project build bin lib)
 
 find_library(QHULL_LIBRARY_DEBUG 
              NAMES ${QHULL_DEBUG_NAME} ${QHULL_RELEASE_NAME}
              HINTS "${QHULL_ROOT}" "$ENV{QHULL_ROOT}"
              PATHS "$ENV{PROGRAMFILES}/QHull" "$ENV{PROGRAMW6432}/QHull" 
+             NO_DEFAULT_PATH
              PATH_SUFFIXES project build bin lib)
 
 if(NOT QHULL_LIBRARY_DEBUG) 

diff --git a/cmake/Modules/FindGLEW.cmake b/cmake/Modules/FindGLEW.cmake
index f6c6e2a..f59a780 100644
--- a/cmake/Modules/FindGLEW.cmake
+++ b/cmake/Modules/FindGLEW.cmake
@@ -41,21 +41,6 @@ IF (WIN32)
 ELSE (WIN32)
 
   IF (APPLE)
-# These values for Apple could probably do with improvement.
-  if (${CMAKE_SYSTEM_VERSION} VERSION_LESS "13.0.0")
-    FIND_PATH( GLEW_INCLUDE_DIR glew.h
-      /System/Library/Frameworks/GLEW.framework/Versions/A/Headers
-      ${OPENGL_LIBRARY_DIR}
-      )
-    SET(GLEW_GLEW_LIBRARY "-framework GLEW" CACHE STRING "GLEW library for OSX")
-  else (${CMAKE_SYSTEM_VERSION} VERSION_LESS "13.0.0")
-    find_package(PkgConfig)
-    pkg_check_modules(glew GLEW)
-    SET(GLEW_GLEW_LIBRARY ${GLEW_LIBRARIES} CACHE STRING "GLEW library for OSX")
-  endif (${CMAKE_SYSTEM_VERSION} VERSION_LESS "13.0.0")
-    SET(GLEW_cocoa_LIBRARY "-framework Cocoa" CACHE STRING "Cocoa framework for OSX")
-  ELSE (APPLE)
-
     FIND_PATH( GLEW_INCLUDE_DIR GL/glew.h
       /usr/include/GL
       /usr/openwin/share/include
diff --git a/cmake/pcl_find_cuda.cmake b/cmake/pcl_find_cuda.cmake
index 2f0425e..0675a55 100644
--- a/cmake/pcl_find_cuda.cmake
+++ b/cmake/pcl_find_cuda.cmake
@@ -1,16 +1,6 @@
 # Find CUDA
 
 
-# Recent versions of cmake set CUDA_HOST_COMPILER to CMAKE_C_COMPILER which
-# on OSX defaults to clang (/usr/bin/cc), but this is not a supported cuda
-# compiler.  So, here we will preemptively set CUDA_HOST_COMPILER to gcc if
-# that compiler exists in /usr/bin.  This will not override an existing cache
-# value if the user has passed CUDA_HOST_COMPILER on the command line.
-if (NOT DEFINED CUDA_HOST_COMPILER AND CMAKE_C_COMPILER_ID STREQUAL "Clang" AND EXISTS /usr/bin/gcc)
-  set(CUDA_HOST_COMPILER /usr/bin/gcc CACHE FILEPATH "Host side compiler used by NVCC")
-  message(STATUS "Setting CMAKE_HOST_COMPILER to /usr/bin/gcc instead of ${CMAKE_C_COMPILER}.  See http://dev.pointclouds.org/issues/979")
-endif()
-
 if(MSVC11)
 	# Setting this to true brakes Visual Studio builds.
 	set(CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE OFF CACHE BOOL "CUDA_ATTACH_VS_BUILD_RULE_TO_CUDA_FILE")
@@ -47,10 +37,5 @@ if(CUDA_FOUND)
 	include(${PCL_SOURCE_DIR}/cmake/CudaComputeTargetFlags.cmake)
 	APPEND_TARGET_ARCH_FLAGS()
     
-  # Send a warning if CUDA_HOST_COMPILER is set to a compiler that is known
-  # to be unsupported.
-  if (CUDA_HOST_COMPILER STREQUAL CMAKE_C_COMPILER AND CMAKE_C_COMPILER_ID STREQUAL "Clang")
-    message(WARNING "CUDA_HOST_COMPILER is set to an unsupported compiler: ${CMAKE_C_COMPILER}.  See http://dev.pointclouds.org/issues/979")
-  endif()
 
 endif()
